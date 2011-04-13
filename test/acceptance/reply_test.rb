require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

class ReplyTest < MiniTest::Unit::TestCase

  include AcceptanceHelper

  def test_user_can_see_replies
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    u2 = Factory(:user)
    u2.feed.updates << Factory(:update, :text => "@#{u.username} Hey man.")

    log_in(u, a.uid)

    visit "/replies"

    assert_match "@#{u.username}", page.body
  end

  def test_user_can_see_replies_with_css_class_mentioned
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    u2 = Factory(:user)
    a2 = Factory(:authorization, :user => u2)
    u2.feed.updates << Factory(:update, :text => "@#{u.username} Hey man.")
    u.feed.updates << Factory(:update, :text => "some text @someone, @#{u2.username} Hey man.")
    log_in(u, a.uid)
    visit "/updates"
    assert_match "class='hentry mention update'", page.body

    log_in(u2, a2.uid)
    visit "/updates"
    assert_match "class='hentry mention update'", page.body
  end
end
