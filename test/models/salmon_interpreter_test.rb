require 'minitest/autorun'
require 'mocha/setup'

require_relative '../../app/models/salmon_interpreter'

module MongoMapper
  class Error < StandardError; end
  class DocumentNotFound < Error; end
end

module RstatUs
  class InvalidSalmonMessage < StandardError; end
end


describe "SalmonInterpreter" do
  describe "#new" do
    it "raises MongoMapper::DocumentNotFound if the feed doesnt exist" do
      id = 99999
      SalmonInterpreter.stubs(:parse).returns(mock)
      SalmonInterpreter.expects(:find_feed)
                       .with(id)
                       .raises(MongoMapper::DocumentNotFound)
      lambda {
        SalmonInterpreter.new("something", :feed_id => id)
      }.must_raise MongoMapper::DocumentNotFound
    end

    it "raises an ArgumentError if the body is empty string" do
      lambda {
        SalmonInterpreter.new("")
      }.must_raise ArgumentError
    end

    it "raises an ArgumentError if the body is nil" do
      lambda {
        SalmonInterpreter.new(nil)
      }.must_raise ArgumentError
    end

    it "raises an ArgumentError if we can't parse the body" do
      body = "<?xml version='1.0' encoding='UTF-8'?><not-salmon-xml />"
      SalmonInterpreter.expects(:parse).with(body).returns(nil)
      SalmonInterpreter.stubs(:find_feed)

      lambda {
        SalmonInterpreter.new(body)
      }.must_raise ArgumentError
    end
  end

  describe "#interpret" do
    before do
      SalmonInterpreter.stubs(:find_feed)
      SalmonInterpreter.stubs(:parse).returns(
        stub_everything(:entry => stub_everything)
      )
    end

    it "returns if the author's url is local" do
      s = SalmonInterpreter.new("something", :root_url => "http://example.com")
      s.expects(:local_user?).returns(true)
      s.expects(:process_activity).never
      assert s.interpret
    end

    describe "remote author" do
      before do
        @s = SalmonInterpreter.new("something")
        @s.stubs(:local_user?).returns(false)
      end

      it "raises an exception if we can't verify the salmon message" do
        @s.stubs(:find_or_initialize_author).returns(stub_everything)
        @s.expects(:message_verified?).returns(false)

        @s.expects(:process_activity).never

        lambda {
          @s.interpret
        }.must_raise RstatUs::InvalidSalmonMessage
      end

      describe "unseen" do
        it "saves the new Author if the message is verified" do
          author = stub_everything(:new? => true)
          @s.expects(:find_or_initialize_author).returns(author)
          @s.expects(:message_verified?).returns(true)

          author.expects(:save!)
          @s.expects(:process_activity)

          @s.interpret
        end

        it "doesn't save the new Author if the message fails verification" do
          author = stub_everything(:new? => true)
          @s.expects(:find_or_initialize_author).returns(author)
          @s.expects(:message_verified?).returns(false)

          author.expects(:save!).never
          @s.expects(:process_activity).never

          lambda {
            @s.interpret
          }.must_raise RstatUs::InvalidSalmonMessage
        end
      end

      describe "seen" do
        it "doesn't save the Author if it isn't new" do
          author = stub_everything(:new? => false)
          @s.expects(:find_or_initialize_author).returns(author)
          @s.expects(:message_verified?).returns(true)

          author.expects(:save!).never
          @s.expects(:process_activity)

          @s.interpret
        end
      end
    end
  end

  describe "#process_activity" do
    before do
      SalmonInterpreter.stubs(:find_feed)
    end

    {
      :post => :post,
      :follow => :follow,
      "http://ostatus.org/schema/1.0/unfollow" => :unfollow,
      "http://ostatus.org/schema/1.0/update-profile" => :update_profile
    }.each do |verb, method|

      it "calls the #{method} method when it gets #{verb} for the verb" do
        activity = stub_everything(:verb => verb)
        entry = stub_everything(:activity => activity)
        SalmonInterpreter.stubs(:parse).returns(
          stub_everything(:entry => entry)
        )

        s = SalmonInterpreter.new("something")

        s.expects(method)
        s.process_activity
      end

    end
  end
end