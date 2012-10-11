require_relative '../acceptance_helper'

  describe "friendships" do
    include AcceptanceHelper
   
    describe "destroy" do
      it "returns a user not found error" do 
        log_in_as_some_user
        user_id = "some-random-id"
        page.driver.post "/api/friendships/destroy.json", {:user_id => user_id}
        parsed_json = JSON.parse(source)
        parsed_json[0].must_equal("User ID does not exist: #{user_id}")
      end
      it "returns a user can not follow same user error" do
        log_in_as_some_user
        page.driver.post "/api/friendships/destroy.json", {:user_id => @u.id}
        parsed_json = JSON.parse(source)
        parsed_json[0].must_equal("Can't unfollow yourself")
      end
      it "returns a user is not following this user error" do
        log_in_as_some_user
        zebra = Fabricate(:user, :username => "zebra")
        page.driver.post "/api/friendships/destroy.json", {:user_id => zebra.id}
        parsed_json = JSON.parse(source)
        parsed_json[0].must_equal("You are not following this user")
      end
      it "returns the unfollowed user" do
        log_in_as_some_user
        zebra = Fabricate(:user, :username => "zebra")
        @u.follow! zebra.feed
        page.driver.post "/api/friendships/destroy.json", {:user_id => zebra.id}
        parsed_json = JSON.parse(source)
        parsed_json["id"].must_equal(zebra.id.to_s)
      end
      it "returns the error for invalid request when no user_id or screen_name is present" do
        log_in_as_some_user
        zebra = Fabricate(:user, :username => "zebra")
        @u.follow! zebra.feed
        page.driver.post "/api/friendships/destroy.json"
        parsed_json = JSON.parse(source)
        parsed_json[0].must_equal("You must specify either user_id or screen_name")
      end
    end
  end

