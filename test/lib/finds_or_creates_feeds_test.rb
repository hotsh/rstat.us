require 'minitest/autorun'
require 'mocha'

require_relative '../../lib/finds_or_creates_feeds'

class Feed
end

describe "when a subscriber id exists" do
  
  it "should return the feed" do
    existing = Feed.new
    Feed.expects(:first).with(:id => "id").returns(existing)

    feed = FindsOrCreatesFeeds.find_or_create("id")
    assert_equal existing, feed
  end
end
