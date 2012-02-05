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
end
