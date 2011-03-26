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
    visit "/users/#{u.username}/feed"
    assert_equal 200, page.status_code
  end

  def test_user_profile
    u = Factory(:user)
    visit "/users/#{u.username}"
    assert_equal 200, page.status_code
  end

  def test_user_follows_themselves_upon_create
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    visit "/users/#{u.username}/following"
    assert_match u.username, page.body
  end

  def test_user_makes_updates
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
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

  def test_user_can_see_replies
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    u2 = Factory(:user)
    u2.feed.updates << Factory(:update, :text => "@#{u.username} Hey man.")

    log_in(u, a.uid)

    visit "/replies"

    assert_match "@#{u.username}", page.body
  end

  def test_user_can_see_world
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    u2 = Factory(:user)
    update = Factory(:update)
    u2.feed.updates << update

    log_in(u, a.uid)

    visit "/updates"

    assert_match update.text, page.body
  end

  def test_subscribe_to_users_on_other_sites
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
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

  def test_user_follow_another_user
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    u2 = Factory(:user)

    log_in(u, a.uid)

    visit "/users/#{u2.username}"

    click_button "follow-#{u2.feed.id}"
    assert_match "Now following #{u2.username}", page.body
  end

  def test_user_unfollow_another_user
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    u2 = Factory(:user)
    a2 = Factory(:authorization, :user => u2)

    log_in(u, a.uid)
    u.follow! u2.feed.url

    visit "/users/#{u2.username}/following"
    click_button "unfollow-#{u2.feed.id}"

    assert_match "No longer following #{u2.username}", page.body
  end

  def test_users_followers_in_order
    aardvark = Factory(:user, :username => "aardvark", :created_at => Date.new(2010, 10, 23))
    zebra    = Factory(:user, :username => "zebra", :created_at => Date.new(2011, 10, 23))
    giraffe  = Factory(:user, :username => "giraffe", :created_at => Date.new(2011, 10, 23))
    leopard  = Factory(:user, :username => "leopard", :created_at => Date.new(2011, 10, 23))
    a = Factory(:authorization, :user => aardvark)

    log_in(aardvark, a.uid)

    visit "/users/#{leopard.username}"
    click_button "follow-#{leopard.feed.id}"

    visit "/users/#{zebra.username}"
    click_button "follow-#{zebra.feed.id}"

    visit "/users/#{aardvark.username}/following"
    assert_match /zebra.*aardvark/m, page.body
  end

  def test_user_following_paginates
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    51.times do
      u2 = Factory(:user)
      u.follow! u2.feed.url
    end

    visit "/users/#{u.username}/following"

    click_link "next_button"

    assert_match "Previous", page.body
    assert_match "Next", page.body
  end

  def test_user_followers_paginates
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    51.times do
      u2 = Factory(:user)
      u2.follow! u.feed.url
    end

    visit "/users/#{u.username}/followers"

    click_link "next_button"

    assert_match "Previous", page.body
    assert_match "Next", page.body
  end

  def test_user_edit_own_profile_link
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    visit "/users/#{u.username}"

    assert has_link? "Edit profile"
  end

  def test_user_edit_profile
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    visit "/users/#{u.username}"
    click_link "Edit profile"

    assert_equal 200, page.status_code
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
  
  def test_user_update_profile_twitter_button
    u = Factory(:user)
    log_in_no_twitter(u)
    visit "/users/#{u.username}/edit"

    assert_match page.body, /Add Twitter Account/
  end
  
  def test_user_update_profile_twitter_button
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :nickname => "Awesomeo the Great")
    log_in(u, a.uid)
    visit "/users/#{u.username}/edit"

    assert_match page.body, /Awesomeo the Great/
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
  
  def no_twitter_login
    u = Factory(:user)
    log_in_no_twitter(u)
    assert_match /Login successful/, page.body
  end
  
  def test_twitter_send_checkbox_present
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    
    assert_match page.body, /Tweet Me/
  end
  
  def test_twitter_send
    update_text = "Test Twitter Text"
    Twitter.expects(:configure)
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    
    fill_in "text", :with => update_text
    check("tweeted")
    click_button "Share"
    
    assert_match /Update created/, page.body
  end
  
  def test_twitter_no_send
    update_text = "Test Twitter Text"
    Twitter.expects(:configure).never
    u = Factory(:user)
    log_in_no_twitter(u)
        
    fill_in "text", :with => update_text
    click_button "Share"
    
    assert_match /Update created/, page.body
  end

  def test_junk_username_gives_404
    visit "/users/1n2i12399992sjdsa21293jj"
    assert_equal 404, page.status_code
  end

  def test_unsupported_feed_type_gives_404
    u = Factory(:user, :username => "dfnkt")
    visit "/users/#{u.username}/feed.json"

    assert_equal 404, page.status_code
  end

  def test_users_browse
    zebra    = Factory(:user, :username => "zebra")
    aardvark = Factory(:user, :username => "aardvark")
    a = Factory(:authorization, :user => aardvark)
    log_in(aardvark, a.uid)

    visit "/users"

    assert has_link? "aardvark"
    assert has_link? "zebra"
  end

  def test_users_browse_paginates
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    51.times do
      u2 = Factory(:user)
    end

    visit "/users"

    click_link "next_button"

    assert_match "Previous", page.body
    assert_match "Next", page.body
  end

  def test_users_browse_shows_latest_users
    aardvark = Factory(:user, :username => "aardvark", :created_at => Date.new(2010, 10, 23))
    zebra    = Factory(:user, :username => "zebra", :created_at => Date.new(2011, 10, 24))
    a = Factory(:authorization, :user => aardvark)

    log_in(aardvark, a.uid)

    visit "/users"
    assert_match /zebra.*aardvark/m, page.body
  end

  def test_users_browse_by_letter
    alpha = Factory(:user, :username => "alpha")
    a = Factory(:authorization, :user => alpha)

    ["apple", "beta", "BANANAS"].each do |u|
      u2 = Factory(:user, :username => u)
    end

    log_in(alpha, a.uid)

    visit "/users"
    click_link "B"

    assert has_link? "beta"
    assert has_link? "BANANAS"
    refute_match "apple", page.body
  end

  def test_users_browse_by_non_letter
    alpha = Factory(:user, :username => "alpha")
    a = Factory(:authorization, :user => alpha)

    ["flop", "__FILE__"].each do |u|
      u2 = Factory(:user, :username => u)
    end

    log_in(alpha, a.uid)

    visit "/users"
    click_link "Other"

    assert has_link? "__FILE__"
    refute_match "flop", page.body
  end

  def test_users_browse_no_results
    alpha = Factory(:user, :username => "alpha")
    a = Factory(:authorization, :user => alpha)

    log_in(alpha, a.uid)

    visit "/users"
    click_link "B"

    assert_match "Sorry, no users that match.", page.body

  end
end

