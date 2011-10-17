require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "Authorization" do
  include AcceptanceHelper

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

  def log_in_new_email_user
    @u = Factory(:user)
    log_in_email(@u)
  end

  # -- The real tests begin here:
  describe "associating users and authorizations" do
    describe "twitter" do
      it "can add twitter to an account" do
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

      it "can remove twitter from an account" do
        log_in_new_twitter_user

        visit "/users/#{@u.username}/edit"

        assert_match /edit/, page.current_url
        click_button "Remove"

        a = Authorization.first(:provider => "twitter", :user_id => @u.id)
        assert a.nil?
      end

      # TODO: Add one for logging in with twitter
      it "signs up with twitter" do
        omni_mock("twitter_user", {:uid => 78654, :token => "1111", :secret => "2222"})
        visit '/auth/twitter'

        assert_match /\/users\/new/, page.current_url

        fill_in "username", :with => "new_user"
        click_button "Finish Signup"

        u = User.first(:username => "new_user")
        refute u.nil?

        auth = Authorization.first :nickname => "twitter_user"
        assert_equal u, auth.user
        assert_equal "1111", auth.oauth_token
        assert_equal "2222", auth.oauth_secret
      end

      it "notifies the user of invalid credentials" do
        omni_error_mock(:invalid_credentials, :provider => :twitter)

        visit '/auth/twitter'

        assert page.has_content?("We were unable to use your credentials to log you in")
        assert_match /\/sessions\/new/, page.current_url
      end

      it "notifies the user if a timeout occurs" do
        omni_error_mock(:timeout, :provider => :twitter)

        visit '/auth/twitter'

        assert page.has_content?("We were unable to use your credentials because of a timeout")
        assert_match /\/sessions\/new/, page.current_url
      end

      it "notifies the user of an unknown error" do
        omni_error_mock(:unknown_error, :provider => :twitter)

        visit '/auth/twitter'

        assert page.has_content?("We were unable to use your credentials")
        assert_match /\/sessions\/new/, page.current_url
      end
    end
  end

  describe "profile" do
    it "has an add twitter account button if no twitter auth" do
      log_in_new_email_user
      visit "/users/#{@u.username}/edit"

      assert_match page.body, /Add Twitter Account/
    end

    it "shows twitter nickname if twitter auth" do
      u = Factory(:user)
      a = Factory(:authorization, :user => u, :nickname => "Awesomeo the Great")
      log_in(u, a.uid)
      visit "/users/#{u.username}/edit"

      assert_match page.body, /Awesomeo the Great/
    end
  end

  describe "updates" do
    describe "twitter" do
      it "has the twitter send checkbox" do
        log_in_new_twitter_user

        assert_match page.body, /Twitter/
        assert find_field('tweet').checked?
      end

      it "sends updates to twitter" do
        Twitter.expects(:update)

        log_in_new_twitter_user

        assert_publish_succeeds "Test Twitter Text"
      end

      it "does not send updates to twitter if the checkbox is unchecked" do
        Twitter.expects(:update).never

        log_in_new_twitter_user
        uncheck("tweet")

        assert_publish_succeeds "Test Twitter Text"
      end
    end

    describe "only email" do
      it "logs in with email and no twitter login" do
        log_in_new_email_user

        assert_match /Login successful/, page.body
        assert_match @u.username, page.body
      end

      it "does not send updates to twitter" do
        Twitter.expects(:update).never

        log_in_new_email_user

        assert_publish_succeeds "Test Twitter Text"
      end
    end
  end

  it "migrates your token" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :oauth_token => nil, :oauth_secret => nil, :nickname => nil)
    log_in(u, a.uid)

    assert_equal "1234", u.twitter.oauth_token
    assert_equal "4567", u.twitter.oauth_secret
    assert_equal u.username, u.twitter.nickname
  end
end
