require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "JSON Unauthenticated reading" do
  include AcceptanceHelper

  it "can request an individual user's timeline in json" do
    u = Fabricate(:user)
    update1 = Fabricate(:update,
                      :text       => "This is a message posted yesterday",
                      :author     => u.author,
                      :created_at => 1.day.ago)
    update2 = Fabricate(:update,
                      :text       => "This is a message posted last week",
                      :author     => u.author,
                      :created_at => 1.week.ago)
    u.feed.updates << update1
    u.feed.updates << update2

    visit "/users/#{u.username}.json"

    assert_match /#{update1.text}.*#{update2.text}/m, page.body
  end
end