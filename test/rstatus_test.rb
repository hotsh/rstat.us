require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
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

  def test_user_profile_redirect
    u = Factory(:user)
    url = "http://www.example.com/users/#{u.username}"
    visit "/users/#{u.username.upcase}"
    assert_equal url, page.current_url
  end

  def test_user_does_not_follow_self_upon_create
    u = Factory(:user)
    refute u.following? u.feed.url
  end

  def test_user_cannot_follow_self
    u = Factory(:user)
    u.follow! u.feed.url
    refute u.following? u.feed.url
  end

  def test_user_makes_updates
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    update_text = "Testing, testing"
    params = {
      :text => update_text
    }
    log_in(u, a.uid)

    VCR.use_cassette('publish_update') do
      visit "/"
      fill_in 'update-textarea', :with => update_text
      click_button :'update-button'
    end

    assert_match page.body, /#{update_text}/
  end

  def test_user_can_make_short_update
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    update_text = "Q"
    params = {
      :text => update_text
    }
    log_in(u, a.uid)

    VCR.use_cassette('publish_short_update') do
      visit "/"
      fill_in 'update-textarea', :with => update_text
      click_button :'update-button'
    end

    refute_match page.body, /Your status is too short!/
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

  def test_user_stays_on_same_route_after_post_update
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    visit "/updates"
    fill_in "text", :with => "Teststring fuer die Ewigkeit ohne UTF-8 Charakter"
    VCR.use_cassette('publish_to_hub') {click_button "Share"}

    assert_match "/updates", page.current_url

    visit "/replies"
    fill_in "text", :with => "Bratwurst mit Pommes rot-weiss"
    VCR.use_cassette('publish_to_hub') {click_button "Share"}

    assert_match "/replies", page.current_url
    
    visit "/"
    fill_in "text", :with => "Buy a test string. Your name in this string for only 1 Euro/character"
    VCR.use_cassette('publish_to_hub') {click_button "Share"}

    assert_match "/", page.current_url    
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

    VCR.use_cassette('subscribe_remote') do
      fill_in 'url', :with => "http://identi.ca/api/statuses/user_timeline/396889.atom"
      click_button "Follow"
    end

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

    visit "/users/#{u.username}/following"
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

    visit "/users/#{zebra.username}"
    click_button "follow-#{zebra.feed.id}"

    visit "/users/#{leopard.username}"
    click_button "follow-#{leopard.feed.id}"

    visit "/users/#{aardvark.username}/following"
    assert_match /leopard.*zebra/m, page.body
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

  def test_user_following_outputs_json
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    u2 = Factory(:user, :username => "user1")
    u.follow! u2.feed.url

    visit "/users/#{u.username}/following.json"

    json = JSON.parse(page.body)
    assert_equal "user1", json.last["username"]
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

  def test_users_browse_by_letter_paginates
    visit "/users"
   
    49.times do
      u2 = Factory(:user)
    end
    u2 = Factory(:user, :username => "uzzzzz")

    click_link "U"
    click_link "next_button"
  
    assert_match u2.username, page.body
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

    ["aardvark", "beta", "BANANAS"].each do |u|
      u2 = Factory(:user, :username => u)
    end

    log_in(alpha, a.uid)

    visit "/users"
    click_link "B"

    assert has_link? "(beta)"
    assert has_link? "(BANANAS)"
    refute_match "(aardvark)", page.body
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
  

  def test_no_user_found_forgot_password
    visit "/forgot_password"
    fill_in "email", :with => "someone@somewhere.com"
    click_button "Send"
    
    assert_match "Your account could not be found, please check your email and try again.", page.body
  end
  
  def test_forgot_password_token_set
    u = Factory(:user, :email => "someone@somewhere.com")
    Notifier.expects(:send_forgot_password_notification)
    assert_nil u.perishable_token
    
    visit "/forgot_password"
    fill_in "email", :with => "someone@somewhere.com"
    click_button "Send"
    
    u = User.first(:email => "someone@somewhere.com")
    refute u.perishable_token.nil?
    assert_match "A link to reset your password has been sent to someone@somewhere.com.", page.body
  end
  
  def test_correct_reset_password_link
    u = Factory(:user, :email => "someone@somewhere.com")
    token = u.set_password_reset_token
    visit "/reset_password/#{token}"
    
    assert_match "Password Reset", page.body
    assert_match "/reset_password/#{token}", page.current_url
  end
  
  def test_incorrect_reset_password_link
    visit "/reset_password/abcd"
    
    assert_match "Your link is no longer valid, please request a new one.", page.body
    assert_match "/forgot_password", page.current_url
  end
  
  def test_expired_reset_password_link
    u = Factory(:user, :email => "someone@somewhere.com")
    token = u.set_password_reset_token
    u.password_reset_sent = 5.days.ago
    u.save
    
    visit "/reset_password/#{token}"
    
    assert_match "Your link is no longer valid, please request a new one.", page.body
    assert_match "/forgot_password", page.current_url
  end
  
  def test_reset_password_no_password_present
    u = Factory(:user, :email => "someone@somewhere.com")
    token = u.set_password_reset_token
    visit "/reset_password/#{token}"
    
    fill_in "password", :with => ""
    click_button "Reset"
    
    assert_match "Password must be present", page.body
    assert_match "/reset_password/#{token}", page.current_url
  end
  
  def test_reset_password_passwords_dont_match
    u = Factory(:user, :email => "someone@somewhere.com")
    token = u.set_password_reset_token
    visit "/reset_password/#{token}"
    
    fill_in "password", :with => "password"
    fill_in "password_confirm", :with => "passrd"
    click_button "Reset"
    
    assert_match "Passwords do not match", page.body
    assert_match "/reset_password/#{token}", page.current_url
  end
  
  def test_successful_password_reset
    u = Factory(:user, :email => "someone@somewhere.com")
    token = u.set_password_reset_token
    visit "/reset_password/#{token}"
    
    fill_in "password", :with => "password"
    fill_in "password_confirm", :with => "password"
    click_button "Reset"
    
    assert_match "Password successfully set", page.body
    assert_match "/", page.current_url
  end

  def test_user_password_reset
    u = Factory(:user, :email => "some@email.com")
    u.password = "password"
    u.save
    pass_hash = u.hashed_password
    log_in_email(u)

    visit "/users/password_reset"
    assert_match "Password Reset", page.body
    
    fill_in "password", :with => "password"
    fill_in "password_confirm", :with => "password"
    click_button "Reset"
    
    u = User.first(:email => "some@email.com")
    assert u.hashed_password != pass_hash
    assert_match "Password successfully set", page.body
    assert_match "/", page.current_url
  end

  def test_user_password_reset_not_logged_in
    visit "/users/password_reset"
    
    assert_match "/forgot_password", page.current_url
  end
  
  def test_user_password_reset_no_email
    user = Factory(:user, :email => nil)
    a = Factory(:authorization, :user => user)
    log_in(user, a.uid)
    
    visit "/users/password_reset"
    
    assert_match "Set Password", page.body
    
    fill_in "email", :with => "some@email.com"
    fill_in "password", :with => "password"
    fill_in "password_confirm", :with => "password"
    click_button "Reset"
    
    u = User.first(:id => user.id)
    refute u.hashed_password.nil?
    refute u.email.nil?
    assert_match "Password successfully set", page.body
    assert_match "/", page.current_url
  end
  
  def test_user_password_reset_email_needed
    u = Factory(:user, :email => nil)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    
    visit "/users/password_reset"
    
    assert_match "Set Password", page.body
    
    fill_in "password", :with => "password"
    fill_in "password_confirm", :with => "password"
    click_button "Reset"
    
    assert_match "Email must be provided", page.body
    assert_match "/users/password_reset", page.current_url
  end
  
  def test_user_password_reset_email_does_not_show
    u = Factory(:user, :email => "something@something.com")
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    
    visit "/users/password_reset"
    
    assert_equal page.has_selector?("input[name=email]"), false
  end
  
  def test_user_password_reset_passwords_dont_match
    u = Factory(:user, :email => "some@email.com")
    log_in_email(u)
  
    visit "/users/password_reset"
    
    fill_in "password", :with => "password"
    fill_in "password_confirm", :with => "pasord"
    click_button "Reset"
    
    assert_match "Passwords do not match", page.body
    assert_match "/users/password_reset", page.current_url
  end
  
  def test_user_password_reset_no_password_present
    u = Factory(:user, :email => "some@email.com")
    log_in_email(u)
  
    visit "/users/password_reset"
    
    click_button "Reset"
    
    assert_match "Password must be present", page.body
    assert_match "/users/password_reset", page.current_url
  end
  
  def test_following_displays_username_logged_in
    u = Factory(:user, :username => "dfnkt")
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    visit "/users/#{u.username}/following"
    assert_match "#{u.username} is following", page.body

  end

  def test_following_displays_username_logged_out
    u = Factory(:user, :username => "dfnkt")

    visit "/users/#{u.username}/following"
    assert_match "#{u.username} is following", page.body
  end

  def test_user_password_reset
    u = Factory(:user, :email => "some@email.com")
    u.password = "password"
    u.save
    pass_hash = u.hashed_password
    log_in_email(u)

    visit "/users/password_reset"
    assert_match "Password Reset", page.body
    
    fill_in "password", :with => "password"
    fill_in "password_confirm", :with => "password"
    click_button "Reset"
    
    u = User.first(:email => "some@email.com")
    assert u.hashed_password != pass_hash
    assert_match "Password successfully set", page.body
    assert_match "/", page.current_url
  end

  def test_user_password_reset_not_logged_in
    visit "/users/password_reset"
    
    assert_match "/forgot_password", page.current_url
  end
  
  def test_user_password_reset_no_email
    user = Factory(:user, :email => nil)
    a = Factory(:authorization, :user => user)
    log_in(user, a.uid)
    
    visit "/users/password_reset"
    
    assert_match "Set Password", page.body
    
    fill_in "email", :with => "some@email.com"
    fill_in "password", :with => "password"
    fill_in "password_confirm", :with => "password"
    click_button "Reset"
    
    u = User.first(:id => user.id)
    refute u.hashed_password.nil?
    refute u.email.nil?
    assert_match "Password successfully set", page.body
    assert_match "/", page.current_url
  end
  
  def test_user_password_reset_email_needed
    u = Factory(:user, :email => nil)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    
    visit "/users/password_reset"
    
    assert_match "Set Password", page.body
    
    fill_in "password", :with => "password"
    fill_in "password_confirm", :with => "password"
    click_button "Reset"
    
    assert_match "Email must be provided", page.body
    assert_match "/users/password_reset", page.current_url
  end
  
  def test_user_password_reset_passwords_dont_match
    u = Factory(:user, :email => "some@email.com")
    log_in_email(u)
  
    visit "/users/password_reset"
    
    fill_in "password", :with => "password"
    fill_in "password_confirm", :with => "pasord"
    click_button "Reset"
    
    assert_match "Passwords do not match", page.body
    assert_match "/users/password_reset", page.current_url
  end
  
  def test_user_password_reset_no_password_present
    u = Factory(:user, :email => "some@email.com")
    log_in_email(u)
  
    visit "/users/password_reset"
    
    click_button "Reset"
    
    assert_match "Password must be present", page.body
    assert_match "/users/password_reset", page.current_url
  end
  
  def test_reset_password_link_for_profile_no_password
    u = Factory(:user, :email => "some@email.com")
    log_in_email(u)

    visit "/users/#{u.username}/edit"

    assert_match "Set Password", page.body
  end
  
  def test_reset_password_link_for_profile
    u = Factory(:user, :email => "some@email.com", :hashed_password => "blerg")
    log_in_email(u)

    visit "/users/#{u.username}/edit"

    assert_match "Reset Password", page.body
  end
  
end

