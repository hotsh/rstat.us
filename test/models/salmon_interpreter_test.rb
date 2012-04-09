require 'minitest/autorun'
require 'mocha'

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
      SalmonInterpreter.stubs(:parse).returns(mock)
    end

    it "returns if the author's url is local" do
      s = SalmonInterpreter.new("something", :root_url => "http://example.com")
      s.expects(:author_uri).returns("http://example.com/user/abcd")
      assert s.interpret
    end

    describe "remote author" do
      before do
        @s = SalmonInterpreter.new("something")
        @s.stubs(:local_user?).returns(false)
      end

      it "raises an exception if we can't verify the salmon message" do
        @s.stubs(:find_or_initialize_author)
        @s.expects(:message_verified?).returns(false)

        lambda {
          @s.interpret
        }.must_raise RstatUs::InvalidSalmonMessage
      end

      describe "unseen" do
        it "saves the new Author if the message is verified" do
          author = mock
          author.stubs(:new?).returns(true)
          @s.expects(:find_or_initialize_author).returns(author)
          @s.expects(:message_verified?).returns(true)

          author.expects(:save!)

          @s.interpret
        end

        it "doesn't save the new Author if the message fails verification" do
          author = mock
          author.stubs(:new?).returns(true)
          @s.expects(:find_or_initialize_author).returns(author)
          @s.expects(:message_verified?).returns(false)

          author.expects(:save!).never

          lambda {
            @s.interpret
          }.must_raise RstatUs::InvalidSalmonMessage
        end
      end
    end
  end
end