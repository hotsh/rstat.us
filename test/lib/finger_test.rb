require 'minitest/autorun'
require 'mocha'

require_relative '../../lib/finger'

describe "when querying web finger" do

  Xrd = Struct.new(:links)

  class Link < Hash
    def initialize(rel, href)
      self['rel']  = rel
      self['href'] = href
    end

    def to_s
      self['href']
    end

    def href
      self['href']
    end
  end

  module Redfinger
  end
  
  before do
    url_link = Link.new('http://schemas.google.com/g/2010#updates-from', 'http://feed.url')
    public_key_link = Link.new('magic-public-key', 'ignored,key')
    salmon_link = Link.new('salmon', 'http://salmon.url')
    xrd = Xrd.new([ url_link, public_key_link, salmon_link ])

    @email = "someone@somewhere.com"

    Redfinger.expects(:finger).with(@email).returns(xrd)

    @finger_data = QueriesWebFinger.query(@email)
  end

  it "should get the remote url" do
    assert_equal "http://feed.url", @finger_data.url
  end
  
  it "should get public key " do
    assert_equal "key", @finger_data.public_key
  end

  it "should get salmon url" do
    assert_equal "http://salmon.url", @finger_data.salmon_url
  end
end
