require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "search" do
  include AcceptanceHelper

  before do
    @update_text = "These aren't the droids you're looking for!"
    log_in_as_some_user
    VCR.use_cassette('publish_update') do
      fill_in 'update-textarea', :with => @update_text
      click_button :'update-button'
    end
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

    it "returns updates on blank search" do
      search_for("")

      within "#search" do
        assert has_content? @update_text
      end
    end

    it "returns updates when you click on the search tab (no search)" do
      visit "/search"

      within "#search" do
        assert has_content? @update_text
      end
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

  describe "pagination" do
    it "does not paginate when there are too few" do
      5.times do
        Fabricate(:update, :text => "Testing pagination LIKE A BOSS")
      end

      search_for("boss")

      refute_match "Previous", page.body
      refute_match "Next", page.body
    end

    it "paginates forward only if on the first page" do
      30.times do
        Fabricate(:update, :text => "Testing pagination LIKE A BOSS")
      end

      search_for("boss")

      refute_match "Previous", page.body
      assert_match "Next", page.body
    end

    it "paginates backward only if on the last page" do
      30.times do |i|
        Fabricate(:update, :text => "#{i} Testing pagination LIKE A BOSS")
      end

      search_for("boss")
      click_link "next_button"

      assert_match "Previous", page.body
      refute_match "Next", page.body
    end

    it "paginates forward and backward if on a middle page" do
      54.times do
        Fabricate(:update, :text => "Testing pagination LIKE A BOSS")
      end

      search_for("boss")
      click_link "next_button"

      assert_match "Previous", page.body
      assert_match "Next", page.body
    end
  end
end
