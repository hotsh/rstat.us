# encoding: UTF-8
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
    assert u.twitter?
  end
  
  def test_user_returns_twitter
    u = Factory.create(:user)
    a = Factory.create(:authorization, :user => u)
    assert_equal a, u.twitter
  end
  
  def test_user_has_facebook
    u = Factory.create(:user)
    a = Factory.create(:authorization, :user => u, :provider => "facebook")
    assert u.facebook?
  end
  
  def test_user_returns_facebook
    u = Factory.create(:user)
    a = Factory.create(:authorization, :user => u, :provider => "facebook")
    assert_equal a, u.facebook
  end
  
  def test_set_reset_password_token
    u = Factory.create(:user)
    assert_nil u.perishable_token
    assert_nil u.password_reset_sent
    u.set_password_reset_token
    refute u.perishable_token.nil?
    refute u.password_reset_sent.nil?
  end
  
  def test_reset_password
    u = Factory.create(:user)
    u.password = "test_password"
    u.save
    prev_pass = u.hashed_password
    u.reset_password("password")
    assert u.hashed_password != prev_pass
  end

  def test_no_special_chars_in_usernames
    ["something@something.com", "another'quirk", ".boundary_case.", "another..case", "another/random\\test", "yet]another", ".Ὁμηρος"].each do |i|
      u = User.new :username => i
      refute u.save, "contains restricted characters."
    end
    ["Ὁμηρος"].each do |i|
      u = User.new :username => i
      assert u.save, "characters being restricted unintentionally."
    end
  end

  def test_username_cant_be_empty
    u = User.new :username => ""
    refute u.save, "blank username"
  end

  def test_username_cant_be_nil
    u = User.new :username => nil
    refute u.save, "nil username"
  end

end
