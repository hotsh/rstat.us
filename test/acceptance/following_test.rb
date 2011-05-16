require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "following" do
  include AcceptanceHelper

  it "doesn't make you follow yourself after signing up" do
    u = Factory(:user)
    refute u.following? u.feed.url
  end

  it "disallows following yourself" do
    u = Factory(:user)
    u.follow! u.feed.url
    refute u.following? u.feed.url
  end

  it "follows users on other sites" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    visit "/"
    click_link "Would you like to follow someone not on rstat.us?"
    assert_match "ostatus Sites", page.body

    VCR.use_cassette('subscribe_remote') do
      fill_in 'url', :with => "http://identi.ca/api/statuses/user_timeline/396889.atom"
      click_button "Follow"
    end

    assert_match "Now following steveklabnik.", page.body
    assert "/", current_path
  end

  it "follows another user" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    u2 = Factory(:user)

    log_in(u, a.uid)

    visit "/users/#{u2.username}"

    click_button "follow-#{u2.feed.id}"
    assert_match "Now following #{u2.username}", page.body
  end

  it "unfollows another user" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    u2 = Factory(:user)
    a2 = Factory(:authorization, :user => u2)

    log_in(u, a.uid)
    u.follow! u2.feed.url

    visit "/users/#{u.username}/following"
    click_button "unfollow-#{u2.feed.id}"

    assert_match "No longer following #{u2.username}", page.body
  end

  it "maintains the order in which you follow people" do
    aardvark = Factory(:user, :username => "aardvark", :created_at => Date.new(2010, 10, 23))
    zebra    = Factory(:user, :username => "zebra", :created_at => Date.new(2011, 10, 23))
    giraffe  = Factory(:user, :username => "giraffe", :created_at => Date.new(2011, 10, 23))
    leopard  = Factory(:user, :username => "leopard", :created_at => Date.new(2011, 10, 23))
    a = Factory(:authorization, :user => aardvark)

    log_in(aardvark, a.uid)

    visit "/users/#{zebra.username}"
    click_button "follow-#{zebra.feed.id}"

    visit "/users/#{leopard.username}"
    click_button "follow-#{leopard.feed.id}"

    visit "/users/#{aardvark.username}/following"
    assert_match /leopard.*zebra/m, page.body
  end

  it "outputs json" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    u2 = Factory(:user, :username => "user1")
    u.follow! u2.feed.url

    visit "/users/#{u.username}/following.json"

    json = JSON.parse(page.body)
    assert_equal "user1", json.last["username"]
  end

  it "does not paginate followers when there are not enough" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    5.times do
      u2 = Factory(:user)
      u2.follow! u.feed.url
    end

    visit "/users/#{u.username}/followers"

    refute_match "Previous", page.body
    refute_match "Next", page.body
  end

  it "paginates the users following you" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    51.times do
      u2 = Factory(:user)
      u2.follow! u.feed.url
    end

    visit "/users/#{u.username}/followers"

    click_link "next_button"

    assert_match "Previous", page.body
    assert_match "Next", page.body
  end

  it "uses your username on your following page if logged in" do
    u = Factory(:user, :username => "dfnkt")
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    visit "/users/#{u.username}/following"
    assert_match "#{u.username} is following", page.body

  end

  it "uses your username on your following page if not logged in" do
    u = Factory(:user, :username => "dfnkt")

    visit "/users/#{u.username}/following"
    assert_match "#{u.username} is following", page.body
  end
end
