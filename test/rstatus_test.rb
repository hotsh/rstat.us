require_relative 'test_helper'

class RstatusTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_hello_world
    get '/'
    assert last_response.ok?
  end

  def test_get_feeds
    feed = Factory(:feed)
    get "/feeds/#{feed.id}"
    assert last_response.ok?, "Response not okay."
  end

end

