require 'minitest/autorun'
require 'mocha'

require_relative '../../lib/finds_or_creates_feeds'

class Feed
end

describe "finding or creating a new feed" do
  before do
    @feed = Feed.new
    @subscriber_id = "id"
  end

  describe "when feed exists with the subscriber id" do
    it "should return the feed" do
      Feed.expects(:first).with(:id => @subscriber_id).returns(@feed)

      feed = FindsOrCreatesFeeds.find_or_create(@subscriber_id)

      assert_equal @feed, feed
    end
  end

  describe "when feed does not have the subscriber id" do

    before do
      Feed.expects(:first).with(:id => @subscriber_id).returns(nil)
      
      @feed_url = "http://some.url"
      @feed_data = FeedData.new(@feed_url, nil)

      stub_converts_subscriber = stub

      ConvertsSubscriberToFeedData.expects(:new)
        .with(@subscriber_id)
        .returns(stub_converts_subscriber)

      stub_converts_subscriber.expects(:get_feed_data!)
        .returns(@feed_data)
    end
    
    describe "when a feed exists with the remote url" do
      it "should return the feed with the remote url " do
        Feed.expects(:first).with(:remote_url => @feed_url).returns(@feed)

        feed = FindsOrCreatesFeeds.find_or_create(@subscriber_id)

        assert_equal @feed, feed
      end
    end

    describe "when a feed does not exist with the remote url" do
      it "should create a new feed from the data" do
        Feed.expects(:first).with(:remote_url => @feed_url).returns(nil)
        Feed.expects(:create_from_feed_data).with(@feed_data).returns(@feed)

        feed = FindsOrCreatesFeeds.find_or_create(@subscriber_id)

        assert_equal @feed, feed
      end
    end
  end
end
