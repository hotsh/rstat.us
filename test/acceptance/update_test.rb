require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "update" do
  include AcceptanceHelper

  it "renders your feed" do
    author = Fabricate(:author)
    feed = author.feed

    feed.updates = (1..5).map { Fabricate(:update) }
    feed.save

    visit "/feeds/#{feed.id}.atom"

    feed.updates.each do |update|
      assert_match page.body, /#{update.text}/
    end
  end

  it "renders the world's updates" do
    log_in_with_twitter

    u2 = Fabricate(:user)
    update = Fabricate(:update)
    u2.feed.updates << update

    visit "/updates"

    assert_match update.text, page.body
  end

  it "makes an update" do
    log_in_with_twitter

    update_text = "Testing, testing"
    params = {
      :text => update_text
    }

    VCR.use_cassette('publish_update') do
      visit "/"
      fill_in 'update-textarea', :with => update_text
      click_button :'update-button'
    end

    assert_match page.body, /#{update_text}/
  end

  it "makes a short update" do
    log_in_with_twitter

    update_text = "Q"
    params = {
      :text => update_text
    }

    VCR.use_cassette('publish_short_update') do
      visit "/"
      fill_in 'update-textarea', :with => update_text
      click_button :'update-button'
    end

    refute_match page.body, /Your status is too short!/
  end

  it "stays on the same page after updating" do
    log_in_with_twitter

    visit "/updates"
    fill_in "text", :with => "Teststring fuer die Ewigkeit ohne UTF-8 Charakter"
    VCR.use_cassette('publish_to_hub') {click_button "Share"}

    assert_match "/updates", page.current_url

    visit "/replies"
    fill_in "text", :with => "Bratwurst mit Pommes rot-weiss"
    VCR.use_cassette('publish_to_hub') {click_button "Share"}

    assert_match "/replies", page.current_url

    visit "/"
    fill_in "text", :with => "Buy a test string. Your name in this string for only 1 Euro/character"
    VCR.use_cassette('publish_to_hub') {click_button "Share"}

    assert_match "/", page.current_url
  end

  it "shows one update" do
    update = Fabricate(:update)

    visit "/updates/#{update.id}"
    assert_match page.body, /#{update.text}/
  end

  it "shows an update in reply to another update" do
    update = Fabricate(:update)
    update2 = Fabricate(:update)
    update2.referral_id = update.id
    update2.save

    visit "/updates/#{update2.id}"
    assert_match page.body, /#{update2.text}/
    assert_match page.body, /#{update.text}/
  end

  describe "update with hashtag" do
    it "creates a working hashtag link" do
      log_in_with_twitter

      visit "/updates"
      fill_in "text", :with => "So this one time #coolstorybro"
      VCR.use_cassette('publish_to_hub') {click_button "Share"}

      visit "/updates"
      click_link "#coolstorybro"
      assert_match "Search Updates", page.body
      assert has_link? "#coolstorybro"
    end
  end

  describe "reply and share links for each update" do
    before do
      log_in_with_twitter

      @u2 = Fabricate(:user)
      @u2.feed.updates << Fabricate(:update, :author => @u2.author)
    end

    it "clicks the reply link from update on a user's page" do
      visit "/users/#{@u2.username}"
      click_link "reply"
      assert_match "What's Going On?", page.body
      assert_match "foo", page.body
    end

    it "clicks the share link from update on a user's page" do
      visit "/users/#{@u2.username}"
      click_link "share"
      assert_match "What's Going On?", page.body
      assert_match "RS @#{@u2.username}: #{@u2.feed.updates.last.text}", page.body
    end
  end

  describe "pagination" do
    it "does not paginate when there are too few" do
      5.times do
        Fabricate(:update)
      end

      u = Fabricate(:user)
      log_in_email(u)
      visit "/updates"

      refute_match "Previous", page.body
      refute_match "Next", page.body
    end

    it "paginates forward only if on the first page" do
      30.times do
        Fabricate(:update)
      end

      u = Fabricate(:user)
      log_in_email(u)
      visit "/updates"

      refute_match "Previous", page.body
      assert_match "Next", page.body
    end

    it "paginates backward only if on the last page" do
      u = Fabricate(:user)
      log_in_email(u)

      30.times do
        Fabricate(:update)
      end

      visit "/updates"
      click_link "next_button"

      assert_match "Previous", page.body
      refute_match "Next", page.body
    end

    it "paginates forward and backward if on a middle page" do
      54.times do
        Fabricate(:update)
      end

      u = Fabricate(:user)
      log_in_email(u)
      visit "/updates"
      click_link "next_button"

      assert_match "Previous", page.body
      assert_match "Next", page.body
    end
  end

  describe "Post to message" do
    it "displays for a twitter user" do
      u = Fabricate(:user)
      a = Fabricate(:authorization, :user => u, :provider => "twitter")
      log_in(u, a.uid)
      visit "/updates"

      assert_match page.body, /Post to/
    end

    it "does not display for an email user" do
      u = Fabricate(:user)
      log_in_email(u)
      visit "/updates"

      refute_match page.body, /Post to/
    end
  end

  describe "no update messages" do
    before do
      log_in_email(Fabricate(:user))
    end

    it "renders tagline default for timeline" do
      visit "/timeline"
      assert_match page.body, /There are no updates here yet/
    end

    it "renders tagline default for replies" do
      visit "/replies"
      assert_match page.body, /There are no updates here yet/
    end

    it "renders locals[:tagline] for search" do
      visit "/search"
      assert_match page.body, /No statuses match your search/
    end
  end

  describe "timeline" do
    before do
      log_in_with_twitter
    end

    it "has a status of myself in my timeline" do
      update = Fabricate(:update, :author => @u.author)
      @u.feed.updates << update
      visit "/"
      assert_match page.body, /#{update.text}/
    end

    it "has a status of someone i'm following in my timeline" do
      u2 = Fabricate(:user)
      update = Fabricate(:update, :author => @u.author)
      u2.feed.updates << update
      @u.follow! u2.feed

      visit "/"
      assert_match page.body, /#{update.text}/
    end

    it "does not have a status of someone i'm not following in my timeline" do
      u2 = Fabricate(:user)
      update = Fabricate(:update, :author => u2.author)
      u2.feed.updates << update

      visit "/"
      refute_match page.body, /#{update.text}/
    end
  end

  describe "world" do
    before do
      log_in_with_twitter
    end

    it "has my updates in the world view" do
      update = Fabricate(:update, :author => @u.author)
      @u.feed.updates << update

      visit "/updates"
      assert_match page.body, /#{update.text}/
    end

    it "has someone i'm following in the world view" do
      u2 = Fabricate(:user)
      update = Fabricate(:update, :author => u2.author)
      u2.feed.updates << update
      @u.follow! u2.feed

      visit "/updates"
      assert_match page.body, /#{update.text}/
    end

    it "has someone i'm not following in the world view" do
      u2 = Fabricate(:user)
      update = Fabricate(:update, :author => u2.author)
      u2.feed.updates << update

      visit "/updates"
      assert_match page.body, /#{update.text}/
    end
  end
end
