require_relative '../acceptance_helper'

describe "Statuses API endpoints" do
  include AcceptanceHelper

  describe "show" do
    it "returns a single status" do
      u = Fabricate(:user)
      update = Fabricate(:update,
                         :text => "Hello World I'm on RStatus",
                         :author => u.author)
      u.feed.updates << update
      author_decorator = AuthorDecorator.decorate(u.author)

      visit "/api/statuses/show/#{u.feed.updates.first.id}.json"

      parsed_json = JSON.parse(source)
      parsed_json["text"].must_equal(update.text)
      parsed_json["user"]["url"].must_equal(author_decorator.absolute_website_url)
      parsed_json["user"]["screen_name"].must_equal(author_decorator.username)
      parsed_json["user"]["name"].must_equal(author_decorator.display_name)
      parsed_json["user"]["profile_image_url"].wont_be_nil
      Time.parse(parsed_json["user"]["created_at"]).to_i.must_equal(author_decorator.created_at.to_i)
      parsed_json["user"]["description"].must_equal(author_decorator.bio)
      parsed_json["user"]["statuses_count"].must_equal(author_decorator.feed.updates.count)
      parsed_json["user"]["friends_count"].must_equal(u.following.length)
      parsed_json["user"]["followers_count"].must_equal(u.followers.length)
    end

    it "returns a single status with trimmed user" do
      u = Fabricate(:user)
      update = Fabricate(:update,
                         :text => "Hello World I'm on RStatus",
                         :author => u.author)
      u.feed.updates << update

      visit "/api/statuses/show/#{u.feed.updates.first.id}.json?trim_user=true"

      parsed_json = JSON.parse(source)
      parsed_json["text"].must_equal(update.text)
      parsed_json["user"].wont_include("url","url should not be included in trimmed status")
      parsed_json["user"].wont_include("screen_name","screen_name should not be included in trimmed status")
      parsed_json["user"].wont_include("name","name should not be included in trimmed status")
      parsed_json["user"].wont_include("profile_image_url","profile_image_url should not be included in trimmed status")
      parsed_json["user"].wont_include("created_at","created_at should not be included in trimmed status")
      parsed_json["user"].wont_include("description","description should not be included in trimmed status")
      parsed_json["user"].wont_include("statuses_count","statuses_count should not be included in trimmed status")
      parsed_json["user"].wont_include("friends_count","friends_count should not be included in trimmed status")
      parsed_json["user"].wont_include("followers_count","followers_count should not be included in trimmed status")
    end
  end

  describe "update" do
    describe "with an authenticated user" do
      describe "with a read+write token" do
        before do
          @app = Fabricate(:doorkeeper_application)
          @u = Fabricate(:user)
          @token = Fabricate(:doorkeeper_access_token,
            :application    => @app,
            :resource_owner_id => @u.id,
            :scopes => "read write"
          )
        end

        it "posts a new update" do
          status = "posting an update from the api!"
          VCR.use_cassette('publish_from_api_to_hub') do
            post "/api/statuses/update.json", {:status => status, :access_token => @token.token}
          end
          last_response.status.must_equal 200
        end
      end

      describe "with only a read token" do
        before do
          @app = Fabricate(:doorkeeper_application)
          @u = Fabricate(:user)
          @token = Fabricate(:doorkeeper_access_token,
            :application    => @app,
            :resource_owner_id => @u.id
          )
        end

        it "returns unauthorized" do
          post "/api/statuses/update.json?access_token=#{@token.token}"
          last_response.status.must_equal 401
        end
      end
    end

    describe "unauthenticated" do
      it "returns unauthorized" do
        post "/api/statuses/update.json"
        last_response.status.must_equal 401
      end
    end
  end

  describe "home_timeline" do
    describe "with an authenticated user" do
      before do
        @app = Fabricate(:doorkeeper_application)
        @u = Fabricate(:user)
        @token = Fabricate(:doorkeeper_access_token,
          :application    => @app,
          :resource_owner_id => @u.id
        )
      end

      it "returns the home timeline for the authenticated user" do
        update = Fabricate(:update,
                           :text => "Hello World I'm on RStatus",
                           :author => @u.author)
        @u.feed.updates << update

        visit "/api/statuses/home_timeline.json?access_token=#{@token.token}"

        parsed_json = JSON.parse(source)
        parsed_json[0]["text"].must_equal(update.text)
      end
    end

    describe "unauthenticated" do
      it "doesnt allow unauthorized access" do
        visit "/api/statuses/home_timeline.json"
        page.status_code.must_equal 401
      end
    end
  end

  describe "user_timeline" do
    before do
      @u = Fabricate(:user)

      5.times do |index|
        update = Fabricate(:update,
                           :text    => "Update test is #{index}",
                           :twitter => true,
                           :author  => @u.author
                         )
       @u.feed.updates << update
      end
    end

    it "returns valid json for a user's timeline" do
      visit "/api/statuses/user_timeline.json?screen_name=#{@u.username}"

      parsed_json = JSON.parse(source)
      parsed_json.length.must_equal 5
      parsed_json[0]["text"].must_equal("Update test is 4")
    end

    it "doesn't freak out if the user has the default avatar" do
      @u.author.email = ""
      @u.author.save

      visit "/api/statuses/user_timeline.json?screen_name=#{@u.username}"
      parsed_json = JSON.parse(source)
      parsed_json[0]["user"]["screen_name"].must_equal(@u.username)
      parsed_json[0]["user"]["profile_image_url"].must_match(
        "http://www.example.com/assets/avatar.png"
      )
    end
  end

  describe "mentions" do
    describe "with an authenticated user" do
      before do
        @app = Fabricate(:doorkeeper_application)
        @u = Fabricate(:user)
        @token = Fabricate(:doorkeeper_access_token,
          :application       => @app,
          :resource_owner_id => @u.id
        )
      end

      it "gives mentions" do
        skip "not implemented"
        update = Fabricate(:update,
                           :text => "@#{@u.username} How about them Bears")

        visit "/api/statuses/mention.json?access_token=#{@token.token}"

        parsed_json = JSON.parse(source)
        parsed_json[0]["text"].must_equal(update.text)
      end
    end

    describe "unauthenticated" do
      it "doesnt allow unauthorized access" do
        visit "/api/statuses/mention.json"
        page.status_code.must_equal 401
      end
    end
  end

  describe "destroy" do
    before do
      @u = Fabricate(:user)
      @update = Fabricate(:update,
                          :text => "Hello World I'm on RStatus",
                          :author => @u.author)
    end

    describe "with an authenticated user and a read+write token" do
      before do
        @app = Fabricate(:doorkeeper_application)
        @token = Fabricate(:doorkeeper_access_token,
          :application       => @app,
          :resource_owner_id => @u.id,
          :scopes            => "read write"
        )
      end

      it "returns an error message when the status is not found" do
        post "/api/statuses/destroy/some-random-id.json?access_token=#{@token.token}"
        parsed_json = JSON.parse(last_response.body)
        parsed_json[0].must_equal("Status ID does not exist: some-random-id")
      end

      it "returns an error message when the user attempting to destroy the status is not the author" do
        another_update = Fabricate(:update)
        post "/api/statuses/destroy/#{another_update.id}.json?access_token=#{@token.token}"
        parsed_json = JSON.parse(last_response.body)
        parsed_json[0].must_equal("I'm afraid I can't let you do that, #{@u.username}.")
      end

      it "returns the status when it is succesfully destroyed" do
        post "/api/statuses/destroy/#{@update.id}.json?access_token=#{@token.token}"

        author_decorator = AuthorDecorator.decorate(@u.author)
        parsed_json = JSON.parse(last_response.body)
        parsed_json["text"].must_equal(@update.text)
        parsed_json["user"]["url"].must_equal(author_decorator.absolute_website_url)
        parsed_json["user"]["screen_name"].must_equal(author_decorator.username)
        parsed_json["user"]["name"].must_equal(author_decorator.display_name)
        parsed_json["user"]["profile_image_url"].wont_be_nil
        Time.parse(parsed_json["user"]["created_at"]).to_i.must_equal(author_decorator.created_at.to_i)
        parsed_json["user"]["description"].must_equal(author_decorator.bio)
        parsed_json["user"]["statuses_count"].must_equal(author_decorator.feed.updates.count)
        parsed_json["user"]["friends_count"].must_equal(@u.following.length)
        parsed_json["user"]["followers_count"].must_equal(@u.followers.length)
      end
    end

    describe "unauthenticated" do
      it "doesnt allow unauthorized access" do
        post "/api/statuses/destroy/#{@update.id}.json"
        last_response.status.must_equal 401
      end
    end
  end
end
