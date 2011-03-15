require_relative 'test_helper'

class RstatusTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_hello_world
    get '/'
    assert last_response.ok?
  end

  def test_get_feeds
    feed = Factory(:feed)
    get "/feeds/#{feed.id}.atom"
    assert last_response.ok?, "Response not okay."
  end

  def test_feed_render
    feed = Factory(:feed)
    updates = []
    5.times do
      updates << Factory(:update)
    end
    feed.updates = updates
    feed.save

    get "/feeds/#{feed.id}.atom"

    updates.each do |update|
      assert_match last_response.body, /#{update.text}/
    end

  end

  def test_user_feed_render
    u = Factory(:user)
    get "/users/#{u.username}/feed"
    assert last_response.ok?

  end

end

