require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

def search_for(query)
  visit "/search"
  fill_in "q", :with => query
  click_button "Search"
end

describe "search" do
  include AcceptanceHelper

  before do
    @update_text = "These aren't the droids you're looking for!"
    Fabricate(:update, :text => @update_text)
  end

  describe "logged in" do
    it "has a link to search when you're logged in" do
      log_in_as_some_user

      visit "/"

      assert has_link? "Search"
    end

    it "allows access to the search page" do
      visit "/search"

      assert_equal 200, page.status_code
      assert_match "/search", page.current_url
    end

    it "allows access to search" do
      search_for("droids")

      assert_match @update_text, page.body
    end
  end

  describe "anonymously" do
    it "allows access to the search page" do
      visit "/search"

      assert_equal 200, page.status_code
      assert_match "/search", page.current_url
    end

    it "allows access to search" do
      search_for("droids")

      assert_match @update_text, page.body
    end
  end

  describe "behavior regardless of authenticatedness" do
    it "gets a match for a word in the update" do
      search_for("droids")

      assert_match @update_text, page.body
    end

    it "doesn't get a match for a substring ending a word in the update" do
      search_for("roids")

      assert_match "No statuses match your search.", page.body
    end

    it "doesn't get a match for a substring starting a word in the update" do
      search_for("loo")

      assert_match "No statuses match your search.", page.body
    end

    it "gets a case-insensitive match for a word in the update" do
      search_for("DROIDS")

      assert_match @update_text, page.body
    end

    it "gets a match for hashtag search" do
      @hashtag_update_text = "This is a test #hashtag"
      Fabricate(:update, :text => @hashtag_update_text)

      search_for("#hashtag")

      assert has_link? "#hashtag"
    end
  end
end
