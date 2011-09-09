require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "user search" do
  include AcceptanceHelper

  it "can search for users" do
    zebra = Factory(:user, :username => "zebra")

    visit "/users"
    fill_in "search", :with => "zebra"
    click_button "Search"

    assert has_content?("zebra")
  end

  it "gets a nice message if there are no users matching the search" do
    visit "/users?search=nonexistentusername"
    assert has_content?("Sorry, no users that match.")
  end
end