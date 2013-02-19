require 'minitest/autorun'
require 'mocha/setup'

require_relative '../../app/services/finger_service'
require_relative '../../app/models/feed_data'
require_relative '../../app/models/finger_data'
require 'redfinger'

module RstatUs
  class InvalidSubscribeTo < StandardError; end
end

describe FingerService do

  describe "finger!" do
    let(:target)                  { "gavinlaking@rstat.us" }
    let(:feed_data)               { mock }
    let(:xrd)                     { mock }
    let(:finger_data)             { mock }
    let(:finger_data_url)         { mock }

    before do
      FeedData.stubs(:new).returns(feed_data)
      Redfinger.stubs(:finger).with(target).returns(xrd)
      FingerData.stubs(:new).with(xrd).returns(finger_data)

      finger_data.stubs(:url).returns(finger_data_url)
      feed_data.stubs(:url=)
      feed_data.stubs(:finger_data=)
    end

    subject { FingerService.new(target).finger! }

    it "returns a FeedData object" do
      subject.must_equal feed_data
    end

    it "gets the url from FingerData" do
      finger_data.expects(:url).returns(finger_data_url)
      subject
    end

    it "sets the FeedData url" do
      feed_data.expects(:url=).with(finger_data_url)
      subject
    end

    it "sets the FeedData finger data" do
      feed_data.expects(:finger_data=).with(finger_data)
      subject
    end

    describe "with a local rstat.us email address that doesn't have a corresponding user" do
      let(:target) { "nobody@rstat.us" }
      before do
        Redfinger.stubs(:finger).with(target).raises(RestClient::ResourceNotFound)
      end

      it "raises a RestClient::ResourceNotFound exception" do
        lambda { subject }.must_raise RstatUs::InvalidSubscribeTo
      end
    end

    describe "with an invalid ostatus email address" do
      let(:target) { "ladygaga@twitter" }

      before do
        Redfinger.stubs(:finger).with(target).raises(SocketError)
      end

      it "raises a SocketError exception" do
        lambda { subject }.must_raise RstatUs::InvalidSubscribeTo
      end
    end
  end
end
