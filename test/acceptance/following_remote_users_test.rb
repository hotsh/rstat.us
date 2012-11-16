require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "following remote users" do
  include AcceptanceHelper

  def follow_remote_user!(webfinger_id = "steveklabnik@identi.ca")
    visit "/"
    click_link "Follow Remote User"

    VCR.use_cassette('subscribe_remote') do
      fill_in 'subscribe_to', :with => webfinger_id
      click_button "Follow"
    end
  end

  describe "success" do
    before do
      log_in_as_some_user
    end

    it "follows users on other sites" do
      follow_remote_user!
      assert_match "Now following steveklabnik.", page.body
      assert "/", current_path
    end

    it "has users on other sites on /following" do
      follow_remote_user!
      visit "/users/#{@u.username}/following"

      assert_match "steveklabnik", page.body
    end

    it "unfollows users from other sites" do
      follow_remote_user!
      visit "/users/#{@u.username}/following"

      VCR.use_cassette('unsubscribe_remote') do
        click_button "Unfollow"
      end

      assert_match "No longer following steveklabnik", page.body
    end

    it "doesn't follow those you already follow, and reports an error" do
      follow_remote_user!
      follow_remote_user!

      assert has_content? "You're already following steveklabnik."
      assert_match "Unfollow", page.body
    end
  end

  describe "failure" do
    it "doesn't look up something that doesn't look like either a webfinger id or a URL" do
      log_in_as_some_user
      visit "/"
      click_link "Follow Remote User"

      follow_remote_page = page.current_url

      fill_in 'subscribe_to', :with => "justinbieber"
      click_button "Follow"

      # Should still be on this page
      page.current_url.must_equal(follow_remote_page)

      within flash do
        assert has_content?("There was a problem following justinbieber. Please specify the whole ID for the person you would like to follow, including both their username and the domain of the site they're on. It should look like an email address-- for example, username@status.net")
      end
    end

    it "especially doesn't look up something that looks like a local file" do
      log_in_as_some_user
      visit "/"
      click_link "Follow Remote User"

      follow_remote_page = page.current_url

      fill_in 'subscribe_to', :with => "Gemfile"
      click_button "Follow"

      # Should still be on this page
      page.current_url.must_equal(follow_remote_page)

      within flash do
        assert has_content?("There was a problem following Gemfile.")
      end
    end
  end
end