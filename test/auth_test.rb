require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'test_helper'

class RstatusAuthTest < MiniTest::Unit::TestCase

  include TestHelper

  # -- Extra assertions and helper methods:

  # publish an update and verify that the app responds successfully
  def assert_publish_succeeds update_text
    VCR.use_cassette('publish_to_hub') do
      fill_in "text", :with => update_text
      click_button "Share"
    end

    assert_match /Update created/, page.body
  end

  def log_in_new_twitter_user
    @u = Factory(:user)
    a = Factory(:authorization, :user => @u)

    log_in(@u, a.uid)
  end

  def log_in_new_fb_user
    @u = Factory(:user)
    a = Factory(:authorization, :user => @u, :provider => "facebook")

    log_in_fb(@u, a.uid)
  end

  def log_in_new_email_user
    @u = Factory(:user)
    log_in_email(@u)
  end

  # -- The real tests begin here:

  def test_add_twitter_to_account
    u = Factory(:user)
    omni_mock(u.username, {:uid => 78654, :token => "1111", :secret => "2222"})

    log_in_email(u)
    visit "/users/#{u.username}/edit"
    click_button "Add Twitter Account"

    auth = Authorization.first(:provider => "twitter", :uid => 78654)
    assert_equal "1111", auth.oauth_token
    assert_equal "2222", auth.oauth_secret
    assert_match "/users/#{u.username}/edit", page.current_url
  end

  def test_twitter_remove
    log_in_new_twitter_user
  
    visit "/users/#{@u.username}/edit"
  
    assert_match /edit/, page.current_url
    click_button "Remove"
  
    a = Authorization.first(:provider => "twitter", :user_id => @u.id)
    assert a.nil?
  end

  def test_add_facebook_to_account
    u = Factory(:user)
    omni_mock(u.username, {:provider => "facebook", :uid => 78654, :token => "1111", :secret => "2222"})

    log_in_email(u)
    visit "/users/#{u.username}/edit"
    click_button "Add Facebook Account"

    auth = Authorization.first(:provider => "facebook", :uid => 78654)
    assert_equal "1111", auth.oauth_token
    assert_equal "2222", auth.oauth_secret
    assert_match "/users/#{u.username}/edit", page.current_url
  end

  def test_facebook_remove
    log_in_new_fb_user
  
    visit "/users/#{@u.username}/edit"
  
    assert_match /edit/, page.current_url
    click_button "Remove"
  
    a = Authorization.first(:provider => "facebook", :user_id => @u.id)
    assert a.nil?
  end

  def test_user_update_profile_twitter_button
    log_in_new_email_user
    visit "/users/#{@u.username}/edit"

    assert_match page.body, /Add Twitter Account/
  end

  def test_user_update_profile_facebook_button
    log_in_new_email_user
    visit "/users/#{@u.username}/edit"

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

  # this test isn't actually being run because it's misnamed.
  # it fails if it's named properly.
  def no_twitter_login
    log_in_new_email_user

    assert_match /Login successful/, page.body
    assert_equal current_user, @u
  end

  def test_twitter_send_checkbox_present
    log_in_new_twitter_user

    assert_match page.body, /Twitter/
    assert_equal find_field('tweet').checked?, true
  end

  def test_facebook_send_checkbox_present
    log_in_new_fb_user

    assert_match page.body, /Facebook/
    assert_equal find_field('facebook').checked?, true
  end

  def test_twitter_send
    Twitter.expects(:update)

    log_in_new_twitter_user

    assert_publish_succeeds "Test Twitter Text"
  end

  def test_facebook_send
    FbGraph::User.expects(:me).returns(mock(:feed! => nil))

    log_in_new_fb_user

    check("facebook")

    assert_publish_succeeds "Test Facebook Text"
  end

  def test_twitter_and_facebook_send
    FbGraph::User.expects(:me).returns(mock(:feed! => nil))
    Twitter.expects(:update)

    # here we're creating a user that has both facebook and twitter authorization
    u = Factory(:user)
    Factory(:authorization, :user => u, :provider => "facebook")
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    check("facebook")
    check("tweet")

    assert_publish_succeeds "Test Facebook and Twitter Text"
  end

  def test_twitter_no_send
    Twitter.expects(:update).never

    log_in_new_twitter_user

    uncheck("tweet")

    assert_publish_succeeds "Test Twitter Text"
  end

  def test_facebook_no_send
    FbGraph::User.expects(:me).never

    log_in_new_fb_user

    uncheck("facebook")

    assert_publish_succeeds "Test Facebook Text"
  end

  def test_no_twitter_no_send
    Twitter.expects(:update).never

    log_in_new_email_user

    assert_publish_succeeds "Test Twitter Text"
  end

  def test_no_facebook_no_send
    FbGraph::User.expects(:me).never

    log_in_new_email_user

    assert_publish_succeeds "Test Facebook Text"
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
    #stubbed to allow testing with new username validation
    existing_user = Factory.build(:user, :username => 'profile.php?id=12345')
    existing_user.expects(:no_special_chars).at_least_once.returns(true)
    existing_user.save
    a = Factory(:authorization, :user => existing_user)
    log_in(existing_user, a.uid)
    click_link "reset_username"
    assert_match /\/reset-username/, page.current_url
    fill_in "username", :with => "janepublic"
    click_button "Update"
    assert_match /janepublic/, page.body
  end

  def test_user_signup_twitter
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

  def test_user_token_migration
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :oauth_token => nil, :oauth_secret => nil, :nickname => nil)
    log_in(u, a.uid)
  
    assert_equal "1234", u.twitter.oauth_token
    assert_equal "4567", u.twitter.oauth_secret
    assert_equal u.username, u.twitter.nickname
  end

end
