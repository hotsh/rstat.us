require_relative "test_helper"

class UpdateTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_at_reply_filter
    u = User.create(:username => "steve")
    update = Update.create(:text => "@steve oh hai!")
    Update.create(:text => "just some other update")

    assert_equal 1, u.at_replies.length
    assert_equal update.id, u.at_replies.first.id
  end

  def test_dm_filter
    u = User.create(:username => "steve")
    update = Update.create(:text => "d steve oh hai!")
    Update.create(:text => "just some other update")

    assert_equal 1, u.dm_replies.length
    assert_equal update.id, u.dm_replies.first.id
  end

  def test_dm_not_in_timeline
    u = User.create(:username => "steve")
    Update.create(:text => "d someone oh hai!", :user_id => u.id)
    update = Update.create(:text => "just some other update", :user_id => u.id)

    assert_equal 1, u.updates.length
    assert_equal update.id, u.updates.first.id 
  end

  def test_hashtag_filter
    User.create(:username => "steve")
    update = Update.create(:text => "mother-effing #hashtags")
    Update.create(:text => "just some other update")

    assert_equal 1, Update.hashtag_search("hashtags").length
    assert_equal update.id, Update.hashtag_search("hashtags").first.id 
  end

end
