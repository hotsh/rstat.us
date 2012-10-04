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

  describe "/updates" do
    before do
      u2 = Fabricate(:user)
      @update = Fabricate(:update)
      u2.feed.updates << @update
    end

    it "renders the world's updates" do
      visit "/updates"
      within "li.hentry" do
        assert has_content? @update.text
      end
    end

    it "responds with HTML by default if Accept header is */*" do
      header "Accept", "*/*"
      get "/updates"

      html = Nokogiri::HTML::Document.parse(last_response.body)
      update_lis = html.css("li.hentry")

      update_lis.length.must_equal(1)
      update_lis.first.text.must_match(@update.text)
    end
  end

  it "makes an update" do
    log_in_as_some_user

    update_text = "Testing, testing"

    VCR.use_cassette('publish_update') do
      visit "/"
      fill_in 'update-textarea', :with => update_text
      click_button :'update-button'
    end

    assert_match page.body, /#{update_text}/
  end

  ["/updates", "/replies", "/"].each do |url|
    it "stays on the #{url} page after making an update there" do
      log_in_as_some_user

      visit url
      fill_in "text", :with => "Buy a test string. Your name in this string for only 1 Euro/character"
      VCR.use_cassette('publish_to_hub') { click_button "Share" }

      assert_match url, page.current_url, "Ended up on #{page.current_url}, expected to be on #{url}"
    end
  end
  
  it "it redirect to the home page after making an update as a reply to another update found on the original updater's profile page" do
    log_in_as_some_user
    u2 = Fabricate(:user)
    reply_update = Fabricate(:update)
    u2.feed.updates << reply_update

    visit "/users/#{u2.username}"
    click_link "reply"
    fill_in "text", :with => "@#{u2.username} This is a great reply update"
    VCR.use_cassette('publish_to_hub') { click_button "Share" }

    assert_equal false, page.current_url.include?("reply="), "Ended up on #{page.current_url}, expected to be on http://www.example.com/"
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
      log_in_as_some_user

      visit "/updates"
      fill_in "text", :with => "So this one time #coolstorybro"
      VCR.use_cassette('publish_to_hub') {click_button "Share"}

      visit "/updates"
      click_link "#coolstorybro"
      assert_match "Search Updates", page.body
      assert has_link? "#coolstorybro"
    end
  end

  describe "destroy" do
    before do
      log_in_as_some_user

      @u.feed.updates << Fabricate(:update, :author => @u.author)
    end

    it "destroys own update" do
      skip "Passing locally but failing on Travis and we don't know why"
      visit "/users/#{@u.username}"
      click_button "I Regret This"

      within 'div.flash' do
        assert has_content? "Update Deleted!"
      end
    end

    it "doesn't destroy not own update" do
      skip "Passing locally but failing on Travis and we don't know why"
      author = Fabricate(:author)
      visit "/users/#{@u.username}"

      Update.any_instance.stubs(:author).returns(author)

      click_button "I Regret This"

      within 'div.flash' do
        assert has_content? "I'm afraid I can't let you do that, #{@u.username}."
      end
    end
  end

  describe "reply and share links for each update" do
    before do
      log_in_as_some_user(:with => :username)

      @u2 = Fabricate(:user)
      @u2.feed.updates << Fabricate(:update, :author => @u2.author)
    end

    it "clicks the reply link from update on a user's page" do
      skip "Passing locally but failing on Travis and we don't know why"
      visit "/users/#{@u2.username}"
      click_link "reply"
      assert_match "What's Going On?", page.body
      assert_match "foo", page.body
    end

    it "clicks the share link from update on a user's page" do
      skip "Passing locally but failing on Travis and we don't know why"
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

      visit "/updates"

      refute_match "Previous", page.body
      refute_match "Next", page.body
    end

    it "paginates forward only if on the first page" do
      30.times do
        Fabricate(:update)
      end

      visit "/updates"

      refute_match "Previous", page.body
      assert_match "Next", page.body
    end

    it "paginates backward only if on the last page" do
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

      visit "/updates"
      click_link "next_button"

      assert_match "Previous", page.body
      assert_match "Next", page.body
    end
  end

  describe "Post to message" do
    it "displays for a twitter user" do
      log_in_as_some_user(:with => :twitter)

      visit "/updates"

      assert_match page.body, /Post to/
    end

    it "does not display for a username user" do
      log_in_as_some_user(:with => :username)

      visit "/updates"

      refute_match page.body, /Post to/
    end
  end

  describe "no update messages" do
    before do
      log_in_as_some_user
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
      log_in_as_some_user
    end

    it "has a status of myself in my timeline" do
      update = Fabricate(:update, :author => @u.author)
      @u.feed.updates << update
      visit "/"
      assert_match page.body, /#{update.text}/
    end

    it "has a status of someone i'm following in my timeline" do
      u2 = Fabricate(:user)
      update = Fabricate(:update, :author => u2.author)
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
      log_in_as_some_user
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
