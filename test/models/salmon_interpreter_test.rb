require 'minitest/autorun'
require 'mocha'

require_relative '../../app/models/salmon_interpreter'

module MongoMapper
  class Error < StandardError; end
  class DocumentNotFound < Error; end
end

describe "SalmonInterpreter" do
  describe "#new" do
    it "raises MongoMapper::DocumentNotFound if the feed doesnt exist" do
      id = 99999
      SalmonInterpreter.stubs(:parse)
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
end