require_relative '../acceptance_helper'

describe "twitter-api" do
  include AcceptanceHelper

  describe "user_timeline" do
    it "returns valid json" do

      log_in_as_some_user

      u = Fabricate(:user)

      5.times do |index|
        update = Fabricate(:update,
                           :text   => "Update test is #{index}",
                           :twitter => true,
                           :author => u.author
                         )
       u.feed.updates << update
      end

      visit "/api/statuses/user_timeline.json?screen_name=#{u.username}"

      parsed_json = JSON.parse(source)
      parsed_json.length.must_equal 5
      parsed_json[0]["text"].must_equal("Update test is 4")

    end
  end

  describe "home_timeline" do
    it "it returns the home timeline for the user" do
      u = Fabricate(:user)
      log_in_username u

      update = Fabricate(:update,
                         :text => "Hello World I'm on RStatus",
                         :author => u.author)
      u.feed.updates << update

      visit "/api/statuses/home_timeline.json"

      parsed_json = JSON.parse(source)
      parsed_json[0]["text"].must_equal(update.text)

    end
  end

  describe "mentions" do
    it "gives mentions" do
      skip "unimplemented"

      u = Fabricate(:user)
      log_in_username u

      update = Fabricate(:update,
                         :text => "@#{u.username} How about them Bears",
                         :author => u.author)

      visit "/api/statuses/mention.json"

      parsed_json = JSON.parse(source)
      parsed_json[0]["text"].must_equal(update.text)

    end
  end

end
