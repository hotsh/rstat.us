require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "search" do
  include AcceptanceHelper

  describe "logged in" do
    it "has a link to search when you're logged in" do
      u = Factory(:user, :email => "some@email.com", :hashed_password => "blerg")
      log_in_email(u)

      visit "/"

      assert has_link? "Search"
    end
  end

  describe "anonymously" do
    it "allows access to search" do
      visit "/search"

      assert_equal 200, page.status_code
      assert_match "/search", page.current_url
    end

    it "actually searches" do
      update_text = "These aren't the droids you're looking for!"
      Factory(:update, :text => update_text)

      visit "/search"

      fill_in "q", :with => "droids"
      click_button "Search"

      assert_match update_text, page.body
    end
  end
end
