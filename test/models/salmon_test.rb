require 'minitest/autorun'
require 'mocha'

require_relative '../../app/models/salmon'

class Salmon
  def self.find_feed(id)
    true
  end

  def self.parse(body)
    true
  end
end

module MongoMapper
  class Error < StandardError; end
  class DocumentNotFound < Error; end
end

describe "Salmon" do
  it "raises MongoMapper::DocumentNotFound if the feed doesnt exist" do
    id = 99999
    Salmon.expects(:find_feed).with(id).raises(MongoMapper::DocumentNotFound)
    lambda {
      Salmon.interpret_entry("request body text", :feed_id => id)
    }.must_raise MongoMapper::DocumentNotFound
  end

  it "raises an ArgumentError if the body is empty" do
    lambda {
      Salmon.interpret_entry("")
    }.must_raise ArgumentError
  end

  it "raises an ArgumentError if we can't parse the body" do
    body = "<?xml version='1.0' encoding='UTF-8'?><not-salmon-xml />"
    Salmon.expects(:parse).with(body).returns(nil)

    lambda {
      Salmon.interpret_entry(body)
    }.must_raise ArgumentError
  end

end