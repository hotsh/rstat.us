require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "ALPS single user" do
  include AcceptanceHelper

  before do
    @user = Fabricate(:user)
    @update = Fabricate(:update)
    @user.feed.updates << @update
  end

  it "can look up and transition to the user's page" do
    visit "/users?search=#{@user.username}"
    user_link = find(:xpath, "//li[contains(@class, 'user') and .//span[contains(@class, 'user-text') and text()='#{@user.username}']]//a[contains(@rel, 'user')]")
    user_link.click

    user_elements = all("div#users ul.single li.user")
    user_elements.length.must_equal(1)
  end

  it "has the user nickname in span.user-text" do
    visit "/users/#{@user.username}"
    within "li.user span.user-text" do
      assert has_content? @user.username
    end
  end

  it "has the user's real name in span.user-name" do
    visit "/users/#{@user.username}"
    within "li.user span.user-name" do
      assert has_content? @user.author.name
    end
  end

  it "has the user's bio in span.description" do
    visit "/users/#{@user.username}"
    within "li.user span.description" do
      assert has_content? @user.author.bio
    end
  end

  it "has the user's website in a rel=website" do
    visit "/users/#{@user.username}"
    within "li.user" do
      assert has_selector?(
        :xpath,
        "//a[contains(@rel, 'website') and @href='#{@user.author.website}']"
      )
    end
  end

  it "has the user's updates" do
    visit "/users/#{@user.username}"
    within "div#messages ul.messages-user li.message" do
      assert has_content? @update.text
    end
  end

  it "has the followers link in a rel=users-followers" do
    visit "/users/#{@user.username}"
    within "li.user" do
      assert has_selector?(
        :xpath,
        "//a[contains(@rel, 'users-followers') and @href='/users/#{@user.username}/followers']"
      )
    end
  end

  it "has the following link in a rel=users-friends" do
    visit "/users/#{@user.username}"
    within "li.user" do
      assert has_selector?(
        :xpath,
        "//a[contains(@rel, 'users-friends') and @href='/users/#{@user.username}/following']"
      )
    end
  end

  it "has the updates link in a rel=messages-me" do
    visit "/users/#{@user.username}"
    within "li.user" do
      assert has_selector?(
        :xpath,
        "//a[contains(@rel, 'messages-me') and @href='#profile_updates']"
      )
    end
  end
end

