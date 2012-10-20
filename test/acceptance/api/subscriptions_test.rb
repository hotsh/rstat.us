require_relative '../acceptance_helper'

describe "friendships" do
  include AcceptanceHelper

  describe "destroy" do
    describe "with an authenticated user and a read+write token" do
      before do
        @u = Fabricate(:user)
        @app = Fabricate(:doorkeeper_application)
        @token = Fabricate(:doorkeeper_access_token,
          :application       => @app,
          :resource_owner_id => @u.id,
          :scopes            => "read write"
        )
      end

      it "returns a user not found error" do
        user_id = "some-random-id"
        post "/api/friendships/destroy.json", {:user_id => user_id, :access_token => @token.token}

        parsed_json = JSON.parse(last_response.body)
        parsed_json[0].must_equal("User ID does not exist: #{user_id}")
      end

      it "returns a user can not follow same user error" do
        post "/api/friendships/destroy.json", {:user_id => @u.id, :access_token => @token.token}

        parsed_json = JSON.parse(last_response.body)
        parsed_json[0].must_equal("Can't unfollow yourself")
      end

      it "returns a user is not following this user error" do
        zebra = Fabricate(:user, :username => "zebra")
        post "/api/friendships/destroy.json", {:user_id => zebra.id, :access_token => @token.token}

        parsed_json = JSON.parse(last_response.body)
        parsed_json[0].must_equal("You are not following this user")
      end

      it "returns the unfollowed user using the delete method" do
        zebra = Fabricate(:user, :username => "zebra")
        @u.follow! zebra.feed
        delete "/api/friendships/destroy.json", {:user_id => zebra.id, :access_token => @token.token}

        parsed_json = JSON.parse(last_response.body)
        parsed_json["id"].must_equal(zebra.id.to_s)
      end

      it "returns the unfollowed user" do
        zebra = Fabricate(:user, :username => "zebra")
        @u.follow! zebra.feed
        post "/api/friendships/destroy.json", {:user_id => zebra.id, :access_token => @token.token}

        parsed_json = JSON.parse(last_response.body)
        parsed_json["id"].must_equal(zebra.id.to_s)
      end

      it "returns the error for invalid request when no user_id or screen_name is present" do
        zebra = Fabricate(:user, :username => "zebra")
        @u.follow! zebra.feed

        post "/api/friendships/destroy.json", {:access_token => @token.token}
        parsed_json = JSON.parse(last_response.body)
        parsed_json[0].must_equal("You must specify either user_id or screen_name")
      end
    end

    describe "unauthenticated" do
      it "doesnt allow unauthorized access" do
        post "/api/friendships/destroy.json"
        last_response.status.must_equal 401
      end
    end
  end

  describe "exists" do
    it "returns true when the relationship exists" do
      zebra = Fabricate(:user, :username => "Zebra")
      pig = Fabricate(:user, :username => "Pig")
      zebra.follow! pig.feed

      get "/api/friendships/exists.json", {:user_id_a => zebra.id, :user_id_b => pig.id}
      last_response.body.must_equal("true")
    end

    it "returns false when the relationship doesn't exist" do
      zebra = Fabricate(:user, :username => "Zebra")
      pig = Fabricate(:user, :username => "Pig")

      get "/api/friendships/exists.json", {:user_id_a => zebra.id, :user_id_b => pig.id}
      last_response.body.must_equal("false")
    end
  end
end
