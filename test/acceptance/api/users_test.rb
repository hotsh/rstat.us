
require_relative '../acceptance_helper'

describe "users" do
  include AcceptanceHelper
  describe "show" do

    it "returns an error that a user_id or screen_name must be specified" do 
      page.driver.get "/api/users/show.json"
      parsed_json = JSON.parse(source)
      parsed_json[0].must_equal("You must specify either user_id or screen_name")
    end
    
    it "returns an error because both the user_id and screen_name can't be specified" do 
      page.driver.get "/api/users/show.json?screen_name=somescreename&user_id=10"
      parsed_json = JSON.parse(source)
      parsed_json[0].must_equal("You can't specify both user_id and screen_name")
    end
  
    it "returns an error because a user does not exist based on screen_name" do
      screen_name = "somescreename"
      page.driver.get "/api/users/show.json?screen_name=#{screen_name}"
      parsed_json = JSON.parse(source)
      parsed_json[0].must_equal("User does not exist: #{screen_name}")
    end
    
    it "returns an error because a user does not exist based on user_id"do
      user_id = 10
      page.driver.get "/api/users/show.json?user_id=#{user_id}"
      parsed_json = JSON.parse(source)
      parsed_json[0].must_equal("User ID does not exist: #{user_id}")
    end

    it "returns a user with the last status inline by user_id" do
      u = Fabricate(:user)
      update = Fabricate(:update,
                         :text => "Hello World I'm on RStatus",
                         :author => u.author)
      u.feed.updates << update
      page.driver.get "/api/users/show.json?user_id=#{u.id}"
      parsed_json = JSON.parse(source)
      parsed_json["id"].must_equal(u.id.to_s)
      parsed_json["status"]["text"].must_equal(update.text)
    end

    it "returns a user with the last status inline by screen_name" do
      u = Fabricate(:user)
      update = Fabricate(:update,
                         :text => "Hello World I'm on RStatus",
                         :author => u.author)
      u.feed.updates << update
      page.driver.get "/api/users/show.json?screen_name=#{u.username}"
      parsed_json = JSON.parse(source)
      parsed_json["id"].must_equal(u.id.to_s)
      parsed_json["status"]["text"].must_equal(update.text)
    end
  end
end
