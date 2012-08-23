require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "twitter-api" do
  include AcceptanceHelper

  describe "user_timeline" do
    it "returns valid json" do
      log_in_as_some_user
      u = Fabricate(:user)
      5.times do
        update = Fabricate(:update,
                         :author => u.author
                         )
        u.feed.updates << update
      end

      visit "/api/statuses/user_timeline.json?screen_name=#{u.username}"

      parsed_json = JSON.parse(source)
      parsed_json.length.must_equal 5
    end
  end
end
