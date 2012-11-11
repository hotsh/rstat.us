require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "Authorization" do
  include AcceptanceHelper

  # publish an update and verify that the app responds successfully
  def assert_publish_succeeds update_text
    VCR.use_cassette('publish_to_hub') do
      fill_in "text", :with => update_text
      click_button "Share"
    end

    assert_match /Update created/, page.body
  end

  # -- The real tests begin here:
  describe "passwords" do
    it "does not place password into the User model" do
      visit '/login'
      fill_in "username", :with => "new_user"
      fill_in "password", :with => "baseball"
      click_button "Log in"

      u = User.first(:username => "new_user")
      refute_respond_to u, :password
    end

    it "does not place password into the Author model" do
      visit '/login'
      fill_in "username", :with => "new_user"
      fill_in "password", :with => "baseball"
      click_button "Log in"

      u = User.first(:username => "new_user")
      refute_respond_to u.author, :password
    end
  end

  describe "associating users and authorizations" do
    describe "username" do
      it "treats the username as being case insensitive" do
        u = Fabricate(:user)
        u.username = u.username.upcase

        log_in_username(u)

        assert page.has_content?("Login successful")
      end

      it "keeps you logged in for a week" do
        log_in_as_some_user(:with => :username)

        assert_equal (Date.today + 1.week), get_me_the_cookie("_rstat.us_session")[:expires].to_date
      end
    end

    describe "twitter" do
      it "can add twitter to an account" do
        u = Fabricate(:user)
        omni_mock(u.username, {:uid => 78654, :token => "1111", :secret => "2222"})

        log_in_username(u)
        visit "/users/#{u.username}/edit"
        click_button "Add Twitter Account"

        auth = Authorization.first(:provider => "twitter", :uid => 78654)
        assert_equal "1111", auth.oauth_token
        assert_equal "2222", auth.oauth_secret
        assert_match "/users/#{u.username}/edit", page.current_url
      end

      it "keeps you logged in for a week" do
        log_in_as_some_user(:with => :twitter)

        assert_equal (Date.today + 1.week), get_me_the_cookie("_rstat.us_session")[:expires].to_date
      end

      it "can remove twitter from an account" do
        log_in_as_some_user(:with => :twitter)

        visit "/users/#{@u.username}/edit"

        assert_match /edit/, page.current_url
        click_button "Remove"

        a = Authorization.first(:provider => "twitter", :user_id => @u.id)
        assert a.nil?
      end

      it "can remove twitter from an account whose username contains a dot" do
        u = Fabricate(:user, :username => 'foo.bar')
        a = Fabricate(:authorization, :user => u)

        log_in_username(u)

        visit "/users/#{u.username}/edit"
        click_button "Remove"

        assert_match /Add Twitter Account/, page.body
      end

      it "cannot remove twitter from an account if you're not logged in" do
        username = "someone_else"
        u = Fabricate(:user, :username => username)
        a = Fabricate(:authorization, :user => u)

        delete "/users/#{username}/auth/#{a.provider}"

        assert Authorization.find(a.id)
      end

      it "cannot remove twitter from an account that isn't yours" do
        username = "someone_else"
        u = Fabricate(:user, :username => username)
        a = Fabricate(:authorization, :user => u)

        log_in_as_some_user

        delete "/users/#{username}/auth/#{a.provider}"

        assert Authorization.find(a.id)
      end

      # TODO: Add one for logging in with twitter
      it "signs up with twitter" do
        omni_mock("twitter_user", {
          :uid => 78654,
          :token => "1111",
          :secret => "2222"
        })
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

      it "has your username already" do
        omni_mock("my_name_is_jonas", {
          :uid => 78654,
          :token => "1111",
          :secret => "2222"
        })
        visit '/auth/twitter'

        assert has_field?("username", :with => "my_name_is_jonas")
      end

      it "sets the author's username for the user_xrd_path (issue #423)" do
        omni_mock("weezer", {
          :uid => 78654,
          :token => "1111",
          :secret => "2222"
        })
        visit '/auth/twitter'

        click_button "Finish Signup"
        u = User.first(:username => "weezer")

        within "#sidebar" do
          assert has_content?(u.username)
          click_link "@#{u.username}"
        end

        assert has_no_content?("No route matches")
      end

      it "notifies the user of invalid credentials" do
        omni_error_mock(:invalid_credentials, :provider => :twitter)

        visit '/auth/twitter'

        within flash do
          assert has_content?(
            "We were unable to use your credentials to log you in"
          )
        end
        assert_match /\/sessions\/new/, page.current_url
      end

      it "notifies the user if a timeout occurs" do
        omni_error_mock(:timeout, :provider => :twitter)

        visit '/auth/twitter'

        within flash do
          assert has_content?(
            "We were unable to use your credentials because of a timeout"
          )
        end
        assert_match /\/sessions\/new/, page.current_url
      end

      it "notifies the user of an unknown error" do
        omni_error_mock(:unknown_error, :provider => :twitter)

        visit '/auth/twitter'

        within flash do
          assert has_content?("We were unable to use your credentials")
        end
        assert_match /\/sessions\/new/, page.current_url
      end
    end

    describe "facebook" do
      it "fails facebook login with a nice error message; not crashing" do
        visit '/auth/facebook/callback'

        within flash do
          assert has_content?("We were unable to use your credentials because we do not support logging in with facebook.")
        end
        page.current_url.must_match(/\/sessions\/new/)
      end
    end

    describe "any provider other than twitter" do
      it "fails with a nice error; we only support login with twitter" do
        visit '/auth/whatever/callback'

        within flash do
          assert has_content?("We were unable to use your credentials because we do not support logging in with whatever.")
        end
        page.current_url.must_match(/\/sessions\/new/)
      end
    end
  end

  describe "profile" do
    describe "without twitter" do
      before do
        log_in_as_some_user(:with => :username)
        visit "/users/#{@u.username}/edit"
      end

      it "has an add twitter account button" do
        assert has_button? "Add Twitter Account"
      end

      it "does not have the post to twitter preference" do
        assert has_no_field? "Always post updates to Twitter?"
      end
    end

    describe "with twitter" do
      before do
        @u = Fabricate(:user)
        a = Fabricate(:authorization, :user => @u, :nickname => "Awesomeo the Great")
        log_in(@u, a.uid, :nickname => a.nickname)
        visit "/users/#{@u.username}/edit"
      end

      it "shows the user's twitter nickname" do
        within ".linked-accounts" do
          text.must_include "Awesomeo the Great"
        end
      end

      it "has a preference about whether to always post updates to twitter" do
        assert has_checked_field? "Always post updates to Twitter?"
      end

      it "saves your updated preference to not always post to twitter" do
        uncheck "Always post updates to Twitter?"
        click_button "Save"
        visit "/users/#{@u.username}/edit"

        assert has_unchecked_field? "Always post updates to Twitter?"
      end

      it "saves your updated preference to always post to twitter after setting it to not" do
        uncheck "Always post updates to Twitter?"
        click_button "Save"
        visit "/users/#{@u.username}/edit"
        check "Always post updates to Twitter?"
        click_button "Save"
        visit "/users/#{@u.username}/edit"
        assert has_checked_field? "Always post updates to Twitter?"
      end
    end
  end

  describe "updates" do
    describe "twitter" do
      it "has the twitter send checkbox" do
        log_in_as_some_user(:with => :twitter)


        assert has_checked_field? 'tweet'
      end

      it "has twitter send unchecked if your preference is to not always send to twitter" do
        @u = Fabricate(:user)
        a = Fabricate(:authorization, :user => @u)
        log_in(@u, a.uid)
        visit "/users/#{@u.username}/edit"
        uncheck "Always post updates to Twitter?"
        VCR.use_cassette('update_twitter_preferences') do
          click_button "Save"
        end
        visit "/"

        assert has_unchecked_field? 'tweet'
      end

      it "sends updates to twitter" do
        Twitter.expects(:update)

        log_in_as_some_user(:with => :twitter)

        assert_publish_succeeds "Test Twitter Text"
      end

      it "does not send updates to twitter if the checkbox is unchecked" do
        Twitter.expects(:update).never

        log_in_as_some_user(:with => :twitter)
        uncheck("tweet")

        assert_publish_succeeds "Test Twitter Text"
      end
    end

    describe "only username" do
      it "logs in with username and no twitter login" do
        log_in_as_some_user(:with => :username)

        within flash do
          assert has_content?("Login successful")
        end
        assert_match @u.username, page.body
      end

      it "does not send updates to twitter" do
        Twitter.expects(:update).never

        log_in_as_some_user(:with => :username)

        assert_publish_succeeds "Test Twitter Text"
      end
    end
  end

  it "migrates your token" do
    u = Fabricate(:user)
    a = Fabricate(:authorization, :user => u, :oauth_token => nil, :oauth_secret => nil, :nickname => nil)
    log_in(u, a.uid)

    assert_equal "1234", u.twitter.oauth_token
    assert_equal "4567", u.twitter.oauth_secret
    assert_equal u.username, u.twitter.nickname
  end
end
