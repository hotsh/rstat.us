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
      text.must_include update.text
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
        text.must_include @update.text
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

  describe "create a new update" do
    it "makes an update" do
      log_in_as_some_user

      update_text = "Testing, testing"

      VCR.use_cassette('publish_update') do
        visit "/"
        fill_in 'update-textarea', :with => update_text
        click_button :'update-button'
      end

      text.must_include update_text
    end

    it "does not allow unauthenticated users to create an update" do
      post "/updates", {:text => "probably spam"}

      last_response.status.must_equal 302
    end
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

  it "redirects to the home page after making an update as a reply to another update found on the original updater's profile page" do
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
    within "#page" do
      text.must_include update.text
    end
  end

  it "shows an update in reply to another update" do
    update = Fabricate(:update)
    update2 = Fabricate(:update)
    update2.referral_id = update.id
    update2.save

    visit "/updates/#{update2.id}"
    within "#page" do
      text.must_include update2.text
      text.must_include update.text
    end
  end

  it "shows an update in reply to another update that has a nil author" do
    # Not sure how this happens, but it does. author_id exists but the
    # associated author does not.
    update = Fabricate(:update, :author_id => "999999")

    update2 = Fabricate(:update)
    update2.referral_id = update.id
    update2.save

    visit "/updates"

    within "#page" do
      text.must_include update2.text
      text.must_include update.text
    end
  end

  describe "update with hashtag" do
    it "creates a working hashtag link" do
      log_in_as_some_user

      visit "/updates"
      fill_in "text", :with => "So this one time #coolstorybro"
      VCR.use_cassette('publish_to_hub') {click_button "Share"}

      visit "/updates"
      click_link "#coolstorybro"

      within "h2" do
        text.must_include "Search Updates"
      end

      assert has_link? "#coolstorybro"
    end
  end

  describe "destroy" do
    before do
      log_in_as_some_user

      @u.feed.updates << Fabricate(:update, :author => @u.author)
    end

    it "destroys own update" do
      heisenbug_log do
        visit "/users/#{@u.username}"
        if has_button? "I Regret This"
          click_button "I Regret This"
        else
          raise Heisenbug
        end

        within 'div.flash' do
          text.must_include "Update Deleted!"
        end
      end
    end

    it "doesn't destroy not own update" do
      heisenbug_log do
        author = Fabricate(:author)
        visit "/users/#{@u.username}"

        Update.any_instance.stubs(:author).returns(author)

        if has_button? "I Regret This"
          click_button "I Regret This"
        else
          raise Heisenbug
        end

        within 'div.flash' do
          text.must_include "I'm afraid I can't let you do that, #{@u.username}."
        end
      end
    end

    it "doesn't let you directly send a delete request without a valid user" do
      u = Fabricate(:update)
      delete "/updates/#{u.id}"

      last_response.status.must_equal 302
    end
  end

  describe "reply and share links for each update" do
    before do
      log_in_as_some_user(:with => :username)

      @u2 = Fabricate(:user)
      @u2.feed.updates << Fabricate(:update, :author => @u2.author)
    end

    it "clicks the reply link from update on a user's page" do
      heisenbug_log do
        visit "/users/#{@u2.username}"

        if has_link? "reply"
          click_link "reply"
        else
          raise Heisenbug
        end
        assert has_field? "update-textarea"
        find("#update-textarea").text.must_match @u2.username
      end
    end

    it "clicks the share link from update on a user's page" do
      heisenbug_log do
        visit "/users/#{@u2.username}"

        if has_link? "share"
          click_link "share"
        else
          raise Heisenbug
        end

        assert has_field? "update-textarea", :with => "RS @#{@u2.username}: #{@u2.feed.updates.last.text}"
      end
    end
  end

  describe "pagination" do
    it "does not paginate when there are too few" do
      5.times do
        Fabricate(:update)
      end

      visit "/updates"

      within ".pagination" do
        text.wont_include "Previous"
        text.wont_include "Next"
      end
    end

    it "paginates forward only if on the first page" do
      30.times do
        Fabricate(:update)
      end

      visit "/updates"

      within ".pagination" do
        text.wont_include "Previous"
        text.must_include "Next"
      end
    end

    it "paginates backward only if on the last page" do
      30.times do
        Fabricate(:update)
      end

      visit "/updates"
      click_link "next_button"

      within ".pagination" do
        text.must_include "Previous"
        text.wont_include "Next"
      end
    end

    it "paginates forward and backward if on a middle page" do
      54.times do
        Fabricate(:update)
      end

      visit "/updates"
      click_link "next_button"

      within ".pagination" do
        text.must_include "Previous"
        text.must_include "Next"
      end
    end
  end

  describe "Post to message" do
    it "displays for a twitter user" do
      log_in_as_some_user(:with => :twitter)
      visit "/updates"

      within "#repost-services" do
        text.must_include "Post to"
      end
    end

    it "does not display for a username user" do
      log_in_as_some_user(:with => :username)
      visit "/updates"

      text.wont_include "Post to"
    end
  end

  describe "no update messages" do
    before do
      log_in_as_some_user
    end

    it "renders tagline default for timeline" do
      visit "/timeline"
      within "#content" do
        text.must_include "There are no updates here yet"
      end
    end

    it "renders tagline default for replies" do
      visit "/replies"
      within "#content" do
        text.must_include "There are no updates here yet"
      end
    end

    it "renders locals[:tagline] for search" do
      visit "/search"
      within "#content" do
        text.must_include "No statuses match your search"
      end
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
      within "#content" do
        text.must_include update.text
      end
    end

    it "has a status of someone i'm following in my timeline" do
      u2 = Fabricate(:user)
      update = Fabricate(:update, :author => u2.author)
      u2.feed.updates << update
      @u.follow! u2.feed

      visit "/"
      within "#content" do
        text.must_include update.text
      end
    end

    it "does not have a status of someone i'm not following in my timeline" do
      u2 = Fabricate(:user)
      update = Fabricate(:update, :author => u2.author)
      u2.feed.updates << update

      visit "/"
      refute_match page.body, update.text
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
      within "#content" do
        text.must_include update.text
      end
    end

    it "has someone i'm following in the world view" do
      u2 = Fabricate(:user)
      update = Fabricate(:update, :author => u2.author)
      u2.feed.updates << update
      @u.follow! u2.feed

      visit "/updates"
      within "#content" do
        text.must_include update.text
      end
    end

    it "has someone i'm not following in the world view" do
      u2 = Fabricate(:user)
      update = Fabricate(:update, :author => u2.author)
      u2.feed.updates << update

      visit "/updates"
      within "#content" do
        text.must_include update.text
      end
    end
  end
end
