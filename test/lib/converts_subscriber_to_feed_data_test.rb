require 'minitest/autorun'
require 'mocha'
require 'socket'

require_relative '../../lib/finds_or_creates_feeds'

FakeFingerData = Struct.new(:url)

module RstatUs
  class InvalidSubscribeTo < StandardError; end
end

describe "converting a subscriber to feed data" do
  describe "when a Safari 'feed://' scheme is provided" do
    it "should replace feed:// with http://" do
      feed_data = ConvertsSubscriberToFeedData.new("feed://stuff").get_feed_data!

      assert_equal "http://stuff", feed_data.url
    end
  end

  describe "when an email address is provided" do
    it "should finger the user" do
      email = "somebody@somewhere.com"
      finger_data = FakeFingerData.new("url")
      QueriesWebFinger.expects(:query).with(email).returns(finger_data)
      new_feed_data = ConvertsSubscriberToFeedData.new(email).get_feed_data!

      assert_equal "url", new_feed_data.url
      assert_equal finger_data, new_feed_data.finger_data
    end
  end

  describe "when an http:// URL is provided" do
    it "should use the subscriber URL as the feed URL" do
      feed_url  = "http://feed.me"
      feed_data = ConvertsSubscriberToFeedData.new(feed_url).get_feed_data!

      assert_equal feed_url, feed_data.url
    end
  end

  describe "when an https:// URL is provided" do
    it "should use the subscriber URL as the feed URL" do
      feed_url  = "https://feed.me"
      feed_data = ConvertsSubscriberToFeedData.new(feed_url).get_feed_data!

      assert_equal feed_url, feed_data.url
    end
  end

  describe "when we cannot currently understand the subscriber URL" do
    it "should raise an exception so that we dont try and look it up as a file" do
      feed_url  = "Gemfile.lock"

      lambda {
        ConvertsSubscriberToFeedData.new(feed_url).get_feed_data!
      }.must_raise(RstatUs::InvalidSubscribeTo)
    end
  end

  describe "when a network error occurs retrieving the subscriber info" do
    it "consumes the SocketError and re-raises at an RstatUs exception" do
      email = "ladygaga@twitter"
      QueriesWebFinger.expects(:query).with(email).throws(SocketError)
      lambda {
        ConvertsSubscriberToFeedData.new(email).get_feed_data!
      }.must_raise(RstatUs::InvalidSubscribeTo)
    end
  end
end
