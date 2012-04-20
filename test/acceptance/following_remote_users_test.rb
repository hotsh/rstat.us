require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "following remote users" do
  include AcceptanceHelper

  describe "success" do
    before do
      log_in_as_some_user
      visit "/"
      click_link "Follow Remote User"

      VCR.use_cassette('subscribe_remote') do
        fill_in 'subscribe_to', :with => "steveklabnik@identi.ca"
        click_button "Follow"
      end
    end

    it "follows users on other sites" do
      assert_match "Now following steveklabnik.", page.body
      assert "/", current_path
    end

    it "has users on other sites on /following" do
      visit "/users/#{@u.username}/following"

      assert_match "steveklabnik", page.body
    end

    it "unfollows users from other sites" do
      visit "/users/#{@u.username}/following"

      VCR.use_cassette('unsubscribe_remote') do
        click_button "Unfollow"
      end

      assert_match "No longer following steveklabnik", page.body
    end

    it "only creates one Feed per remote_url" do
      log_in_as_some_user
      visit "/"
      click_link "Follow Remote User"

      assert_match "OStatus Sites", page.body

      VCR.use_cassette('subscribe_remote') do
        fill_in 'subscribe_to', :with => "steveklabnik@identi.ca"
        click_button "Follow"
      end

      visit "/users/#{@u.username}/following"

      assert_match "Unfollow", page.body
    end
  end
end