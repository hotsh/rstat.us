require_relative "test_helper"

class UserTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_at_reply_filter
    u = User.create(:username => "steve")
    update = Update.create(:text => "@steve oh hai!")
    Update.create(:text => "just some other update")

    assert_equal 1, u.at_replies({}).length
    assert_equal update.id, u.at_replies({}).first.id
  end

  def test_hashtag_filter
    User.create(:username => "steve")
    update = Update.create(:text => "mother-effing #hashtags")
    Update.create(:text => "just some other update")

    assert_equal 1, Update.hashtag_search("hashtags", {}).length
    assert_equal update.id, Update.hashtag_search("hashtags", {}).first.id 
  end

  def test_username_is_unique
    Factory(:user, :username => "steve")
    u = Factory.build(:user, :username => "steve")
    refute u.save
  end
  
  def test_user_has_twitter
    u = Factory.create(:user)
    a = Factory.create(:authorization, :user => u)
    assert_equal true, u.twitter?
  end
  
  def test_user_returns_twitter
    u = Factory.create(:user)
    a = Factory.create(:authorization, :user => u)
    assert_equal a, u.twitter
  end
  
  def test_user_has_facebook
    u = Factory.create(:user)
    a = Factory.create(:authorization, :user => u, :provider => "facebook")
    assert_equal true, u.facebook?
  end
  
  def test_user_returns_facebook
    u = Factory.create(:user)
    a = Factory.create(:authorization, :user => u, :provider => "facebook")
    assert_equal a, u.facebook
  end

end
