require 'minitest/autorun'
require 'mocha'

require_relative '../../lib/finds_or_creates_feeds'

FakeFingerData = Struct.new(:url)

module RstatUs
  class InvalidSubscribeTo < StandardError; end
end

describe "converting subscriber to feed data" do
  describe "when the subscriber info has feed in it" do
    it "should replace the feed with http" do
      feed_data = ConvertsSubscriberToFeedData.get_feed_data("feed://stuff")

      assert_equal "http://stuff", feed_data.url
    end
  end

  describe "when the subscriber info is an email address" do
    it "should finger the user" do
      email = "somebody@somewhere.com"
      finger_data = FakeFingerData.new("url")
      QueriesWebFinger.expects(:query).with(email).returns(finger_data)

      new_feed_data = ConvertsSubscriberToFeedData.get_feed_data(email)

      assert_equal "url", new_feed_data.url
      assert_equal finger_data, new_feed_data.finger_data
    end
  end

  describe "when the subscriber info is an http url" do
    it "should use the subscriber url as the feed url" do
      feed_url  = "http://feed.me"

      feed_data = ConvertsSubscriberToFeedData.get_feed_data(feed_url)

      assert_equal feed_url, feed_data.url
    end

    it "should use an https subscriber url as the feed url" do
      feed_url  = "https://feed.me"

      feed_data = ConvertsSubscriberToFeedData.get_feed_data(feed_url)

      assert_equal feed_url, feed_data.url
    end
  end

  describe "when the subscriber info is neither an email address nor an http url" do
    it "should raise an exception so that we dont try and look it up as a file" do
      feed_url  = "Gemfile.lock"

      lambda {
        ConvertsSubscriberToFeedData.get_feed_data(feed_url)
      }.must_raise(RstatUs::InvalidSubscribeTo)
    end
  end

  describe "when a network error occurs retrieving the subscriber info" do
    it "should not raise a socket error" do
      email = "ladygaga@twitter"
      QueriesWebFinger.expects(:query).with(email).throws(SocketError)
      lambda {
        ConvertsSubscriberToFeedData.get_feed_data(email)
      }.must_raise(RstatUs::InvalidSubscribeTo)
    end
  end
end
