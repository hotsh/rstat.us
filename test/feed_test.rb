require_relative "test_helper"

class FeedTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_user_id_is_required
    feed = Factory.build(:feed, :user_id => nil)
    refute feed.save
  end

  def test_user_name_is_required
    feed = Factory.build(:feed, :user_name => nil)
    refute feed.save
  end

  def test_user_username_is_required
    feed = Factory.build(:feed, :user_username => nil)
    refute feed.save
  end

  def test_user_email_is_required
    feed = Factory.build(:feed, :user_email => nil)
    refute feed.save
  end

  def test_user_website_is_required
    feed = Factory.build(:feed, :user_website => nil)
    refute feed.save
  end

end
