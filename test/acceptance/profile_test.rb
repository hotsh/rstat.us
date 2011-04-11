require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

class ProfileTest < MiniTest::Unit::TestCase

  include AcceptanceHelper

  def test_user_profile_redirect
    u = Factory(:user)
    url = "http://www.example.com/users/#{u.username}"
    visit "/users/#{u.username.upcase}"
    assert_equal url, page.current_url
  end

  def test_user_edit_own_profile_link
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    visit "/users/#{u.username}"

    assert has_link? "Edit profile"
  end

  def test_user_update_profile
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    visit "/users/#{u.username}/edit"
    bio_text = "To be or not to be"
    fill_in "bio", :with => bio_text
    click_button "Save"

    assert_match page.body, /#{bio_text}/
  end
end
