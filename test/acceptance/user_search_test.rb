require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "user search" do
  include AcceptanceHelper

  before do
    zebra = Fabricate(:user, :username => "zebra")
  end

  it "can search for users" do
    visit "/users"
    fill_in "search", :with => "zebra"
    click_button "Search"

    assert has_content?("zebra")
  end

  it "gets a nice message if there are no users matching the search" do
    visit "/users?search=nonexistentusername"
    assert has_no_content?("zebra")
    assert has_content?("Sorry, no users that match.")
  end

  it "displays all users if there is no search query" do
    visit "/users?search="
    assert_equal 200, page.status_code
    assert has_content?("zebra")
  end

  it "finds users by substring regex match (do we want this?)" do
    visit "/users?search=ebr"
    assert has_content?("zebra")
  end

  it "copes an with asterisk in the search string" do
    visit "/users?search=*"
    assert_equal 200, page.status_code, "search input (*) caused a #{page.status_code} response"
    assert has_content?("Please enter a valid search term"), "search input (*) did not cause a flash message"
  end

  it "copes with URL-escaped input in the search string" do
    %w[ ? + {1} {1,} {1,2}].each do |n|
      visit "/users?search=#{CGI.escape(n)}"
      assert_equal 200, page.status_code, "search input #{n} caused a #{page.status_code} response"
      assert has_content?("Please enter a valid search term"), "search input #{n} did not cause a flash message"
    end
  end

  it "finds users case-insensitively" do
    visit "/users?search=ZEBR"
    assert has_content?("zebra")
  end

  describe "pagination" do
    it "does not paginate when there are too few" do
      5.times do
        Fabricate(:user)
      end

      visit "/users?search=user"

      refute_match "Previous", page.body
      refute_match "Next", page.body
    end

    it "paginates forward only if on the first page" do
      30.times do
        Fabricate(:user)
      end

      visit "/users?search=user"

      refute_match "Previous", page.body
      assert_match "Next", page.body
    end

    it "paginates backward only if on the last page" do
      30.times do
        Fabricate(:user)
      end

      visit "/users?search=user"
      click_link "next_button"

      assert_match "Previous", page.body
      refute_match "Next", page.body
    end

    it "paginates forward and backward if on a middle page" do
      54.times do
        Fabricate(:user)
      end

      visit "/users?search=user"
      click_link "next_button"

      assert_match "Previous", page.body
      assert_match "Next", page.body
    end
  end

end
