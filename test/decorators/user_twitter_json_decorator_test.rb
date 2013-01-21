require_relative '../test_helper'

describe UserTwitterJsonDecorator do
  include TestHelper

  describe '#to_json, which implicitly calls as_json' do
    describe "a user with the default avatar" do
      before do
        @user = Fabricate(:user)
        @user.author.email = ""
        @user.author.save

        @root_url       = "https://example.com"
        @decorated_user = UserTwitterJsonDecorator.decorate(@user)
      end

      it "can handle a user with the default avatar" do
        @json        = @decorated_user.to_json(:root_url => @root_url)
        @parsed_json = JSON.parse(@json)
        @parsed_json["profile_image_url"].must_equal "#{@root_url}/assets/avatar.png"
      end

      it "requires a root_url option" do
        lambda {
          @json = @decorated_user.to_json
        }.must_raise ArgumentError
      end
    end

    describe "include_status => true" do
      describe "with updates" do
        it "returns the latest update" do
          user = Fabricate(:user)
          update = Fabricate(:update,
                             :text => "Hello World I'm on RStatus",
                             :author => user.author)
          user.feed.updates << update

          root_url       = "https://example.com"
          decorated_user = UserTwitterJsonDecorator.decorate(user)

          json           = decorated_user.to_json(
                             :root_url       => root_url,
                             :include_status => true
                           )
          parsed_json    = JSON.parse(json)

          parsed_json["status"]["text"].must_equal(update.text)
        end
      end

      describe "without any updates" do
        it "doesnt freak out" do
          user           = Fabricate(:user)
          root_url       = "https://example.com"
          decorated_user = UserTwitterJsonDecorator.decorate(user)

          json           = decorated_user.to_json(
                             :root_url       => root_url,
                             :include_status => true
                           )
          parsed_json    = JSON.parse(json)

          parsed_json["id"].must_equal user.id.to_s
        end
      end
    end
  end
end