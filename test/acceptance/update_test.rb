require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "update" do
  include AcceptanceHelper

  it "renders your feed" do
    feed = Factory(:feed)

    updates = []
    5.times do
      updates << Factory(:update)
    end

    feed.updates = updates
    feed.save

    visit "/feeds/#{feed.id}.atom"

    updates.each do |update|
      assert_match page.body, /#{update.text}/
    end
  end

  it "renders the world's updates" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    u2 = Factory(:user)
    update = Factory(:update)
    u2.feed.updates << update

    log_in(u, a.uid)

    visit "/updates"

    assert_match update.text, page.body
  end

  it "makes an update" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    update_text = "Testing, testing"
    params = {
      :text => update_text
    }
    log_in(u, a.uid)

    VCR.use_cassette('publish_update') do
      visit "/"
      fill_in 'update-textarea', :with => update_text
      click_button :'update-button'
    end

    assert_match page.body, /#{update_text}/
  end

  it "makes a short update" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    update_text = "Q"
    params = {
      :text => update_text
    }
    log_in(u, a.uid)

    VCR.use_cassette('publish_short_update') do
      visit "/"
      fill_in 'update-textarea', :with => update_text
      click_button :'update-button'
    end

    refute_match page.body, /Your status is too short!/
  end

  it "stays on the same page after updating" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

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
    update = Factory(:update)

    visit "/updates/#{update.id}"
    assert_match page.body, /#{update.text}/
  end

  it "shows an update in reply to another upate" do
    update = Factory(:update)
    update2 = Factory(:update)
    update2.referral_id = update.id
    update2.save

    visit "/updates/#{update2.id}"
    assert_match page.body, /#{update2.text}/
    assert_match page.body, /#{update.text}/
  end

  describe "pagination" do
    it "does not paginate when there are too few" do
      5.times do
        Factory(:update)
      end

      u = Factory(:user)
      log_in_email(u)
      visit "/updates"

      refute_match "Previous", page.body
      refute_match "Next", page.body
    end

    it "paginates forward only if on the first page" do
      30.times do
        Factory(:update)
      end

      u = Factory(:user)
      log_in_email(u)
      visit "/updates"

      refute_match "Previous", page.body
      assert_match "Next", page.body
    end

    it "paginates backward only if on the last page" do
      u = Factory(:user)
      log_in_email(u)

      30.times do
        Factory(:update)
      end

      visit "/updates"
      click_link "next_button"

      assert_match "Previous", page.body
      refute_match "Next", page.body
    end

    it "paginates forward and backward if on a middle page" do
      54.times do
        Factory(:update)
      end

      u = Factory(:user)
      log_in_email(u)
      visit "/updates"
      click_link "next_button"

      assert_match "Previous", page.body
      assert_match "Next", page.body
    end
  end

  describe "Post to message" do
    it "displays for a twitter user" do
      u = Factory(:user)
      a = Factory(:authorization, :user => u, :provider => "twitter")
      log_in(u, a.uid)
      visit "/updates"

      assert_match page.body, /Post to/
    end

    it "displays for a facebook user" do
      u = Factory(:user)
      a = Factory(:authorization, :user => u, :provider => "facebook")
      log_in_fb(u, a.uid)
      visit "/updates"

      assert_match page.body, /Post to/
    end

    it "does not display for an email user" do
      u = Factory(:user)
      log_in_email(u)
      visit "/updates"

      refute_match page.body, /Post to/
    end

    it "renders tagline for timeline" do
      u = Factory(:user)
      log_in_email(u)
      visit "/timeline"

      assert_match page.body, /There are no updates here yet/
    end

    it "renders tagline for replies" do
      u = Factory(:user)
      log_in_email(u)
      visit "/replies"

      assert_match page.body, /There are no updates here yet/
    end
  end
end
