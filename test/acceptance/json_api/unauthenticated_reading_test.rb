require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "JSON Unauthenticated reading" do
  include AcceptanceHelper

  it "can request an individual user's timeline in json" do
    u = Fabricate(:user)
    update0 = Fabricate(:update,
                      :text       => "This is a message posted yesterday",
                      :author     => u.author,
                      :created_at => 1.day.ago)
    update1 = Fabricate(:update,
                      :text       => "This is a message posted last week",
                      :author     => u.author,
                      :created_at => 1.week.ago)
    u.feed.updates << update0
    u.feed.updates << update1

    visit "/users/#{u.username}.json"

    parsed_json = JSON.parse(source)

    parsed_json["author"]["username"].must_equal(u.username)
    parsed_json["updates"][0]["text"].must_equal(update0.text)
    parsed_json["updates"][1]["text"].must_equal(update1.text)
  end
end