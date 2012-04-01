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
end