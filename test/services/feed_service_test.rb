require_relative '../test_helper'

require 'mocha/setup'

describe FeedService do
  describe "#find_or_create!" do
    let(:service)       { FeedService.new(target_feed) }
    let(:existing_feed) { mock }
    let(:new_feed)      { mock }

    describe "when the feed can be found by ID" do
      # the BSON ID of user 'gavinlaking@rstat.us' (follow me!)
      let(:target_feed)   { "505cc1beb4f2cd000200022c" }

      before do
        Feed.stubs(:first)
          .with(has_entry(:id, target_feed))
          .returns(existing_feed)
      end

      it "returns the feed" do
        service.find_or_create!.must_equal existing_feed
      end
    end

    describe "when the feed has a local URL" do
      let(:target_feed) { "someone@example.com" }
      let(:service)     { FeedService.new(target_feed, "http://example.com/") }
      let(:user)        { mock }
      let(:author)      { mock }
      let(:feed)        { mock }
      let(:uri)         { mock }

      describe "when the feed exists" do
        before do
          User.stubs(:find_by_case_insensitive_username).returns(user)
          user.stubs(:author).returns(author)
          Kernel.stubs(:URI).returns(uri)
          uri.stubs(:host).returns("example.com")
          author.stubs(:feed).returns(feed)

          service.stubs(:find_feed_by_id).returns(nil)
          service.stubs(:find_feed_by_remote_url).returns nil
        end

        it "returns the feed" do
          service.find_or_create!.must_equal feed
        end
      end

      describe "when the feed does not exist" do
        before do
          User.stubs(:find_by_case_insensitive_username).returns(nil)
          Kernel.stubs(:URI).returns(uri)
          uri.stubs(:host).returns("example.com")

          service.stubs(:find_feed_by_id).returns(nil)
          service.stubs(:find_feed_by_remote_url).returns(existing_feed)
        end

        it "moves on to trying to find by remote url" do
          service.find_or_create!.must_equal existing_feed
        end
      end
    end

    describe "when the feed can by found by remote URL" do
      # the remote URL of user 'gavinlaking@rstat.us' (follow me!)
      let(:target_feed)   { "https://rstat.us/feeds/505cc1beb4f2cd000200022c.atom" }
      let(:feed_data_cov) { mock }
      let(:feed_data)     { mock }

      before do
        Feed.stubs(:first)
          .with(has_entry(:remote_url, "feed_url"))
          .returns(existing_feed)
        SubscriberToFeedDataConverter.stubs(:new).returns(feed_data_cov)
        feed_data_cov.stubs(:get_feed_data!).returns(feed_data)
        feed_data.stubs(:url).returns("feed_url")

        service.stubs(:find_feed_by_id).returns nil
        service.stubs(:find_feed_by_username).returns nil
      end

      it "returns the feed" do
        service.find_or_create!.must_equal existing_feed
      end
    end

    describe "when the feed doesn't exist" do
      let(:target_feed) { "gavinlaking@rstat.us" } # (follow me!)
      let(:feed_data_cov) { mock }
      let(:feed_data)     { mock }

      before do
        service.stubs(:find_feed_by_id).returns nil
        service.stubs(:find_feed_by_username).returns nil
        service.stubs(:find_feed_by_remote_url).returns nil
        SubscriberToFeedDataConverter.stubs(:new).returns(feed_data_cov)
        feed_data_cov.stubs(:get_feed_data!).returns(feed_data)
      end

      it "creates the feed" do
        Feed.expects(:create_and_populate!)
          .with(feed_data)
          .returns(new_feed)
        service.find_or_create!.must_equal new_feed
      end
    end
  end
end
