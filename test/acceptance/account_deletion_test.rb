require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "Delete your account" do
  include AcceptanceHelper

  before do
    @u = Fabricate(:user)
    @update = Fabricate(:update)
    @u.feed.updates << @update
    log_in_username(@u)
  end

  it "lets you delete your account and deletes all your updates" do
    visit "/users/#{@u.username}/edit"
    click_link "Delete Account"

    fill_in "username_confirmation", :with => @u.username
    click_button "Delete Account"

    within flash do
      assert has_content?("Your account has been deleted. We're sorry to see you go.")
    end

    assert logged_out?

    visit "/updates"
    within "#updates" do
      assert has_no_content?(@update.text)
    end
  end

  it "returns you to your edit page if you click cancel" do
    visit "/users/#{@u.username}/edit"
    click_link "Delete Account"
    click_link "Cancel"
    page.current_url.must_match("/users/#{@u.username}/edit")
  end

  it "returns you to your edit page if you dont type a username" do
    visit "/users/#{@u.username}/edit"
    click_link "Delete Account"
    click_button "Delete Account"

    page.current_url.must_match("/users/#{@u.username}/edit")
    within flash do
      assert has_content?("Nothing was deleted since you did not type your username.")
    end
  end

  it "returns you to your edit page if you type your username wrong" do
    visit "/users/#{@u.username}/edit"
    click_link "Delete Account"
    fill_in "username_confirmation", :with => "nopenopenope"
    click_button "Delete Account"

    page.current_url.must_match("/users/#{@u.username}/edit")
    within flash do
      assert has_content?("Nothing was deleted since you did not type your username.")
    end
  end

  it "does not let you delete someone else's account" do
    @someone_else = Fabricate(:user, :username => "someone_else")
    delete "/users/someone_else"

    visit "/users/someone_else"
    within "span.user-text" do
      assert has_content?("someone_else")
    end
  end
end
