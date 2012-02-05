require 'minitest/autorun'
require 'mocha'

require_relative '../../lib/finds_or_creates_feeds'

FakeFingerData = Struct.new(:url)

describe "converting subscriber to feed data" do
  describe "when the subscriber url has feed in it" do
    it "should replace the feed with http" do
      feed_data = ConvertsSubscriberToFeedData.get_feed_data("feed://stuff")

      assert_equal "http://stuff", feed_data.url
    end
  end

  describe "when the subscriber info is an email address " do
    it "should finger the user" do
      email = "somebody@somewhere.com"
      finger_data = FakeFingerData.new("url")
      QueriesWebFinger.expects(:query).with(email).returns(finger_data)

      new_feed_data = ConvertsSubscriberToFeedData.get_feed_data(email)

      assert_equal "url", new_feed_data.url
      assert_equal finger_data, new_feed_data.finger_data
    end
  end
  
  describe "when the subscriber is an http url " do
    it "should use the subscriber url as the feed url" do
      feed_url  = "http://feed.me"

      feed_data = ConvertsSubscriberToFeedData.get_feed_data(feed_url)

      assert_equal feed_url, feed_data.url
    end
  end
end
