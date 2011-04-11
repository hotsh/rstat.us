require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

class SignupTest < MiniTest::Unit::TestCase

  include AcceptanceHelper

  def test_user_signup
    u = User.first(:username => "new_user")
    assert u.nil?

    visit '/login'
    fill_in "username", :with => "new_user"
    fill_in "password", :with => "mypassword"
    click_button "Log in"

    u = User.first(:username => "new_user")
    refute u.nil?
    assert User.authenticate("new_user", "mypassword")
  end

  def test_username_clash
    existing_user = Factory(:user, :username => "taken")
    new_user = Factory.build(:user, :username => 'taken')

    old_count = User.count
    log_in(new_user)
    assert_match /users\/new/, page.current_url, "not on the new user page."

    fill_in "username", :with => "nottaken"
    click_button "Finish Signup"

    assert_match /Thanks! You're all signed up with nottaken for your username./, page.body
    assert_match /\//, page.current_url
  end
end
