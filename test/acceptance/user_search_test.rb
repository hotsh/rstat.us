require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "user search" do
  include AcceptanceHelper

  before do
    zebra = Factory(:user, :username => "zebra")
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

  it "finds users case-insensitively" do
    visit "/users?search=ZEBR"
    assert has_content?("zebra")
  end
end