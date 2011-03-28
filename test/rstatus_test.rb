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
    visit "/"
    fill_in 'update-textarea', :with => update_text
    click_button :'update-button'

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

  def test_user_update_profile_twitter_button
    u = Factory(:user)
    log_in_email(u)
    visit "/users/#{u.username}/edit"
  
    assert_match page.body, /Add Twitter Account/
  end
  
  def test_user_update_profile_facebook_button
    u = Factory(:user)
    log_in_email(u)
    visit "/users/#{u.username}/edit"
  
    assert_match page.body, /Add Facebook Account/
  end
  
  def test_user_profile_with_twitter
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :nickname => "Awesomeo the Great")
    log_in(u, a.uid)
    visit "/users/#{u.username}/edit"
  
    assert_match page.body, /Awesomeo the Great/
  end
  
  def test_user_profile_with_facebook
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :provider => "facebook", :nickname => "Awesomeo the Great")
    log_in_fb(u, a.uid)
    visit "/users/#{u.username}/edit"
  
    assert_match page.body, /Awesomeo the Great/
  end
  
  def no_twitter_login
    u = Factory(:user)
    log_in_email(u)
    assert_match /Login successful/, page.body
    assert_equal current_user, u
  end
  
  def test_twitter_send_checkbox_present
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
  
    assert_match page.body, /Twitter/
    assert_equal find_field('tweet').checked?, true
  end
  
  def test_facebook_send_checkbox_present
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :provider => "facebook")
    log_in_fb(u, a.uid)
  
    assert_match page.body, /Facebook/
    assert_equal find_field('facebook').checked?, true
  end
  
  def test_twitter_send
    update_text = "Test Twitter Text"
    Twitter.expects(:update)
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
  
    fill_in "text", :with => update_text
    check("tweet")
    click_button "Share"
  
    assert_match /Update created/, page.body
  end
  
  def test_facebook_send
    update_text = "Test Facebook Text"
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :provider => "facebook")
    FbGraph::User.expects(:me).returns(mock(:feed! => nil))
  
    log_in_fb(u, a.uid)
  
    fill_in "text", :with => update_text
    check("facebook")
    click_button "Share"
  
    assert_match /Update created/, page.body
  end
  
  def test_twitter_and_facebook_send
    update_text = "Test Facebook and Twitter Text"
    FbGraph::User.expects(:me).returns(mock(:feed! => nil))    
    Twitter.expects(:update)
  
    u = Factory(:user)
    Factory(:authorization, :user => u, :provider => "facebook")
    a = Factory(:authorization, :user => u)
  
    log_in(u, a.uid)
      
    fill_in "text", :with => update_text
    check("facebook")
    check("tweet")
    click_button "Share"
  
    assert_match /Update created/, page.body
  end
  
  def test_twitter_no_send
    update_text = "Test Twitter Text"
    Twitter.expects(:update).never
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
  
    fill_in "text", :with => update_text
    uncheck("tweet")
    click_button "Share"
  
    assert_match /Update created/, page.body
  end
  
  def test_facebook_no_send
    update_text = "Test Facebook Text"
    FbGraph::User.expects(:me).never
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :provider => "facebook")
    log_in_fb(u, a.uid)
  
    fill_in "text", :with => update_text
    uncheck("facebook")
    click_button "Share"
  
    assert_match /Update created/, page.body
  end
  
  def test_no_twitter_no_send
    update_text = "Test Twitter Text"
    Twitter.expects(:update).never
    u = Factory(:user)
    log_in_email(u)
      
    fill_in "text", :with => update_text
    click_button "Share"
  
    assert_match /Update created/, page.body
  end
  
  def test_no_facebook_no_send
    update_text = "Test Facebook Text"
    FbGraph::User.expects(:me).never
    u = Factory(:user)
    log_in_email(u)
      
    fill_in "text", :with => update_text
    click_button "Share"
  
    assert_match /Update created/, page.body
  end

  def test_add_twitter_to_account
    u = Factory(:user)
    OmniAuth.config.add_mock(:twitter, {
      :uid => "78654",
      :user_info => {
        :name => "Joe Public",
        :nickname => u.username,
        :urls => { :Website => "http://rstat.us" },
        :description => "A description",
        :image => "/images/something.png"
      },
      :credentials => {:token => "1111", :secret => "2222"}
    })
    log_in_email(u)
    visit "/users/#{u.username}/edit"
    click_button "Add Twitter Account"
  
    auth = Authorization.first(:provider => "twitter", :uid => 78654)
    assert_equal "1111", auth.oauth_token
    assert_equal "2222", auth.oauth_secret
    assert_match "/users/#{u.username}/edit", page.current_url
  end

  def test_twitter_remove
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    
    visit "/users/#{u.username}/edit"
    
    assert_match /edit/, page.current_url
    click_button "Remove"
    
    a = Authorization.first(:provider => "twitter", :user_id => u.id)
    assert_equal a.nil?, true
  end

  def test_add_facebook_to_account
    u = Factory(:user)
    OmniAuth.config.add_mock(:facebook, {
      :uid => 78654,
      :user_info => {
        :name => "Joe Public",
        :email => "joe@public.com",
        :nickname => u.username,
        :urls => { :Website => "http://rstat.us" },
        :description => "A description",
        :image => "/images/something.png"
      },
      :credentials => {:token => "1111", :secret => "2222"}
    })
    log_in_email(u)
    visit "/users/#{u.username}/edit"
    click_button "Add Facebook Account"
  
    auth = Authorization.first(:provider => "facebook", :uid => 78654)
    assert_equal "1111", auth.oauth_token
    assert_equal "2222", auth.oauth_secret
    assert_match "/users/#{u.username}/edit", page.current_url
  end
  
  def test_facebook_remove
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :provider => "facebook")
    log_in_fb(u, a.uid)
    
    visit "/users/#{u.username}/edit"
    
    assert_match /edit/, page.current_url
    click_button "Remove"
    
    a = Authorization.first(:provider => "facebook", :user_id => u.id)
    assert_equal a.nil?, true
  end

  def test_facebook_username
    new_user = Factory.build(:user, :username => 'profile.php?id=12345')
    log_in_fb(new_user)
    assert_match /users\/new/, page.current_url, "not on the new user page."
  
    fill_in "username", :with => "janepublic"
    click_button "Finish Signup"
    assert_match /Thanks! You're all signed up with janepublic for your username./, page.body
    assert_match /\//, page.current_url
    click_link "Logout"
    log_in_fb(new_user)
    assert_match /janepublic/, page.body
  end

  def test_existing_profile_php_rename_user
    existing_user = Factory(:user, :username => 'profile.php?id=12345')
    a = Factory(:authorization, :user => existing_user)
    log_in(existing_user, a.uid)
    click_link "reset_username"
    assert_match /\/reset-username/, page.current_url
    fill_in "username", :with => "janepublic"
    click_button "Update"
    assert_match /janepublic/, page.body
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

  def test_user_signup_twitter
    Author.any_instance.stubs(:valid_gravatar?).returns(:false)
    omni_mock("twit")
    visit '/auth/twitter'

    assert_match /Confirm account information/, page.body
    assert_match /\/users\/confirm/, page.current_url

    fill_in "username", :with => "new_user"
    fill_in "email", :with => "new_user@email.com"
    click_button "Finish Signup"

    u = User.first(:username => "new_user")
    refute u.nil?
    assert_equal u.email, "new_user@email.com"

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
  
  def test_user_token_migration
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :oauth_token => nil, :oauth_secret => nil, :nickname => nil)
    log_in(u, a.uid)
    
    assert_equal "1234", u.twitter.oauth_token
    assert_equal "4567", u.twitter.oauth_secret
    assert_equal u.username, u.twitter.nickname
    
  end

end

