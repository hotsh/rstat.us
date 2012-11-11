require_relative '../test_helper'

require 'mocha'

describe FeedService do
  include TestHelper

  describe "#find_or_create!" do
    let(:service)       { FeedService.new(target_feed) }
    let(:existing_feed) { mock }
    let(:new_feed)      { mock }

    subject { service.find_or_create! }

    describe "when the feed can be found by ID" do
      # the BSON ID of user 'gavinlaking@rstat.us' (follow me!)
      let(:target_feed)   { "505cc1beb4f2cd000200022c" }

      before do
        service.stubs(:find_feed_by_id).returns(existing_feed)
      end

      it "the feed is returned" do
        service.find_or_create!.must_equal existing_feed
        subject
      end
    end

    describe "when the feed can by found by remote URL" do
      # the remote URL of user 'gavinlaking@rstat.us' (follow me!)
      let(:target_feed)   { "https://rstat.us/feeds/505cc1beb4f2cd000200022c.atom" }

      before do
        service.stubs(:find_feed_by_id).returns nil
        service.stubs(:find_feed_by_remote_url).returns(existing_feed)
      end

      it "the feed is returned" do
        service.find_or_create!.must_equal existing_feed
        subject
      end
    end

    describe "when the feed doesn't exist" do
      let(:target_feed) { "gavinlaking@rstat.us" } # (follow me!)

      before do
        service.stubs(:find_feed_by_id).returns nil
        service.stubs(:find_feed_by_remote_url).returns nil
        service.stubs(:create_feed_from_feed_data).returns(new_feed)
      end

      it "must be created instead" do
        service.find_or_create!.must_equal new_feed
        subject
      end
    end

  end
end