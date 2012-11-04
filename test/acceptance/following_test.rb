require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "following" do
  include AcceptanceHelper

  describe "yourself" do
    it "doesn't make you follow yourself after signing up" do
      u = Fabricate(:user)
      refute u.following_url? u.feed.url
    end

    it "disallows following yourself" do
      u = Fabricate(:user)
      u.follow! u.feed
      refute u.following_url? u.feed.url
    end
  end

  describe "on rstat.us" do
    it "follows another user" do
      log_in_as_some_user

      u2 = Fabricate(:user)

      visit "/users/#{u2.username}"

      click_button "follow-#{u2.feed.id}"
      assert_match "Now following #{u2.username}", page.body
    end

    it "unfollows another user" do
      heisenbug_log do
        log_in_as_some_user

        u2 = Fabricate(:user)
        a2 = Fabricate(:authorization, :user => u2)

        @u.follow! u2.feed

        visit "/users/#{@u.username}/following"

        if has_button? "unfollow-#{u2.feed.id}"
          click_button "unfollow-#{u2.feed.id}"
        else
          raise Heisenbug
        end

        within flash do
          assert has_content? "No longer following #{u2.username}"
        end
      end
    end
  end

  describe "/following" do
    it "maintains the order in which you follow people" do
      log_in_as_some_user

      zebra    = Fabricate(:user, :username => "zebra")
      leopard  = Fabricate(:user, :username => "leopard")

      @u.follow! zebra.feed
      @u.follow! leopard.feed

      visit "/users/#{@u.username}/following"
      assert_match /leopard.*zebra/m, page.body
    end

    it "responds with HTML by default if Accept header is */*" do
      log_in_as_some_user

      u2 = Fabricate(:user, :username => "user1")
      @u.follow! u2.feed

      header "Accept", "*/*"
      get "/users/#{@u.username}/following"

      html = Nokogiri::HTML::Document.parse(last_response.body)
      users = html.css("li.user")

      users.first.text.must_match("user1")
    end


    it "outputs json" do
      log_in_as_some_user

      u2 = Fabricate(:user, :username => "user1")
      @u.follow! u2.feed

      visit "/users/#{@u.username}/following.json"

      json = JSON.parse(page.source)
      assert_equal "user1", json.last["username"]
    end

    it "properly displays title on your following page when logged in" do
      log_in_as_some_user

      visit "/users/#{@u.username}/following"
      assert_match /You're following/, page.body

    end

    it "uses your username if not logged in" do
      u = Fabricate(:user, :username => "dfnkt")

      visit "/users/#{u.username}/following"
      assert_match "#{u.username} is following", page.body
    end

    it "redirects to the correct case" do
      u = Fabricate(:user, :username => "dfnkt")

      visit "/users/#{u.username.upcase}/following"
      assert_match "#{u.username} is following", page.body
      assert_match /\/users\/#{u.username}\/following$/, page.current_url
    end

    it "404s if the requested user does not exist" do
      visit "/users/nonexistent/following"
      assert_match "The page you were looking for doesn't exist.", page.body
    end

    it "has a nice message if not following anyone" do
      u = Fabricate(:user, :username => "dfnkt")

      visit "/users/#{u.username}/following"

      assert_match "No one yet", page.body
    end

    describe "pagination" do
      before do
        log_in_as_some_user

        5.times do
          u2 = Fabricate(:user)
          @u.follow! u2.feed
        end
      end

      it "does not paginate when there are too few" do
        visit "/users/#{@u.username}/following"

        refute_match "Previous", page.body
        refute_match "Next", page.body
      end

      it "paginates forward only if on the first page" do
        visit "/users/#{@u.username}/following?per_page=3"

        refute_match "Previous", page.body
        assert_match "Next", page.body
      end

      it "paginates backward only if on the last page" do
        visit "/users/#{@u.username}/following?per_page=3"
        click_link "next_button"

        assert_match "Previous", page.body
        refute_match "Next", page.body
      end

      it "paginates forward and backward if on a middle page" do
        visit "/users/#{@u.username}/following?per_page=2"

        click_link "next_button"

        assert_match "Previous", page.body
        assert_match "Next", page.body
      end
    end
  end

  describe "/followers" do
    it "maintains the order in which people follow you" do
      log_in_as_some_user

      zebra    = Fabricate(:user, :username => "zebra")
      leopard  = Fabricate(:user, :username => "leopard")

      zebra.follow! @u.feed
      leopard.follow! @u.feed

      visit "/users/#{@u.username}/followers"
      assert_match /leopard.*zebra/m, page.body
    end

    it "properly displays title on your followers page when logged in" do
      log_in_as_some_user

      visit "/users/#{@u.username}/followers"
      assert_match /Your followers/, page.body

    end

    it "uses your username if not logged in" do
      u = Fabricate(:user, :username => "dfnkt")

      visit "/users/#{u.username}/followers"
      assert_match "#{u.username}'s followers", page.body
    end

    it "redirects to the correct case" do
      u = Fabricate(:user, :username => "dfnkt")

      visit "/users/#{u.username.upcase}/followers"
      assert_match "#{u.username}'s followers", page.body
      assert_match /\/users\/#{u.username}\/followers$/, page.current_url
    end

    it "404s if the requested user does not exist" do
      visit "/users/nonexistent/followers"
      assert_match "The page you were looking for doesn't exist.", page.body
    end

    it "has a nice message if not followed by anyone" do
      u = Fabricate(:user, :username => "dfnkt")

      visit "/users/#{u.username}/followers"

      assert_match "No one yet", page.body
    end

    describe "pagination" do
      before do
        log_in_as_some_user

        5.times do
          u2 = Fabricate(:user)
          u2.follow! @u.feed
        end
      end

      it "does not paginate when there are too few" do
        visit "/users/#{@u.username}/followers"

        refute_match "Previous", page.body
        refute_match "Next", page.body
      end

      it "paginates forward only if on the first page" do
        visit "/users/#{@u.username}/followers?per_page=3"

        refute_match "Previous", page.body
        assert_match "Next", page.body
      end

      it "paginates backward only if on the last page" do
        visit "/users/#{@u.username}/followers?per_page=3"
        click_link "next_button"

        assert_match "Previous", page.body
        refute_match "Next", page.body
      end

      it "paginates forward and backward if on a middle page" do
        visit "/users/#{@u.username}/followers?per_page=2"

        click_link "next_button"

        assert_match "Previous", page.body
        assert_match "Next", page.body
      end
    end
  end
end
