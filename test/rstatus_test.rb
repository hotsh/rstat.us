require_relative 'test_helper'

class RstatusTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_hello_world
    visit '/'
    assert_equal 200, page.status_code
  end

  def test_visit_feeds
    feed = Factory(:feed)
    visit "/feeds/#{feed.id}.atom"
    assert_equal 200, page.status_code
  end

  def test_feed_render
    feed = Factory(:feed)
    updates = []
    5.times do
      updates << Factory(:update)
    end
    feed.updates = updates
    feed.save

    visit "/feeds/#{feed.id}.atom"

    updates.each do |update|
      assert_match page.body, /#{update.text}/
    end

  end

  def test_user_feed_render
    u = Factory(:user)
    u.finalize("http://example.com")
    visit "/users/#{u.username}/feed"
    assert_equal 200, page.status_code
  end

  def test_user_profile
    u = Factory(:user)
    u.finalize("http://example.com")
    visit "/users/#{u.username}"
    assert_equal 200, page.status_code
  end

  def test_user_makes_updates
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    u.finalize("http://example.com/")
    update_text = "Testing, testing"
    params = {
      :text => update_text
    }
    log_in(u, a.uid)
    visit "/"
    fill_in 'update-textarea', :with => update_text
    click_button :'update-button'
    visit "/users/#{u.username}/feed"

    assert_match page.body, /#{update_text}/
  end

  def test_subscribe_to_users_on_other_sites
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    u.finalize("http://example.com/")
    log_in(u, a.uid)
    visit "/"
    click_link "Would you like to follow someone not on rstat.us?"
    assert_match "ostatus Sites", page.body

    #this should really be mocked
    fill_in 'url', :with => "http://identi.ca/api/statuses/user_timeline/396889.atom"
    click_button "Follow"
    assert_match "Now following steveklabnik.", page.body
    assert "/", current_path
  end

  def test_user_edit_own_profile_link
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    u.finalize("http://example.com/")
    log_in(u, a.uid)
    visit "/users/#{u.username}"

    assert has_link? "Edit your profile"
  end

  def test_user_edit_profile
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    u.finalize("http://example.com/")
    log_in(u, a.uid)
    visit "/users/#{u.username}"
    click_link "Edit your profile"

    assert_equal 200, page.status_code
  end

  def test_user_update_profile
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    u.finalize("http://example.com/")
    log_in(u, a.uid)
    visit "/users/#{u.username}/edit"
    bio_text = "To be or not to be"
    fill_in "bio", :with => bio_text
    click_button "Save"

    assert_match page.body, /#{bio_text}/
  end

end

