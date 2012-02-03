require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "user browse" do
  include AcceptanceHelper

  it "can browse users" do
    zebra    = Fabricate(:user, :username => "zebra")
    aardvark = Fabricate(:user, :username => "aardvark")
    a = Fabricate(:authorization, :user => aardvark)
    log_in(aardvark, a.uid)

    visit "/users"

    assert has_link? "aardvark"
    assert has_link? "zebra"
  end

  describe "sorted by creation date (default)" do
    it "sorts by latest users by default" do
      aardvark = Fabricate(:user, :username => "aardvark", :created_at => Date.new(2010, 10, 23))
      zebra    = Fabricate(:user, :username => "zebra", :created_at => Date.new(2011, 10, 24))
      a = Fabricate(:authorization, :user => aardvark)

      log_in(aardvark, a.uid)

      visit "/users"
      assert_match /zebra.*aardvark/m, page.body
    end

    describe "pagination" do
      before do
        u = Fabricate(:user)
        a = Fabricate(:authorization, :user => u)

        log_in(u, a.uid)

        5.times do
          u2 = Fabricate(:user)
        end
      end

      it "does not paginate when there are too few" do
        visit "/users"

        refute_match "Previous", page.body
        refute_match "Next", page.body
      end

      it "paginates forward only if on the first page" do
        visit "/users?per_page=3"

        refute_match "Previous", page.body
        assert_match "Next", page.body
      end

      it "paginates backward only if on the last page" do
        visit "/users?per_page=3"

        click_link "next_button"

        refute_match "Next", page.body
        assert_match "Previous", page.body
      end

      it "paginates forward and backward if on a middle page" do
        visit "/users?per_page=2"

        click_link "next_button"

        assert_match "Previous", page.body
        assert_match "Next", page.body
      end
    end
  end

  describe "by letter" do
    it "filters to usernames starting with that letter" do
      alpha = Fabricate(:user, :username => "alpha")
      a = Fabricate(:authorization, :user => alpha)

      ["aardvark", "beta", "BANANAS"].each do |u|
        u2 = Fabricate(:user, :username => u)
      end

      log_in(alpha, a.uid)

      visit "/users"
      click_link "B"

      assert has_link? "(beta)"
      assert has_link? "(BANANAS)"
      refute_match "(aardvark)", page.body
    end

    it "filters usernames starting with nonletters into Other" do
      alpha = Fabricate(:user, :username => "alpha")
      a = Fabricate(:authorization, :user => alpha)

      ["flop", "__FILE__"].each do |u|
        u2 = Fabricate(:user, :username => u)
      end

      log_in(alpha, a.uid)

      visit "/users"
      click_link "Other"

      assert has_link? "__FILE__"
      refute_match "flop", page.body
    end

    it "displays a message if there are no users for that letter" do
      alpha = Fabricate(:user, :username => "alpha")
      a = Fabricate(:authorization, :user => alpha)

      log_in(alpha, a.uid)

      visit "/users"
      click_link "B"

      assert_match "Sorry, no users that match.", page.body
    end

    describe "pagination" do
      before do
        u = Fabricate(:user, :username => "alpha")
        a = Fabricate(:authorization, :user => u)

        log_in(u, a.uid)

        5.times do
          u2 = Fabricate(:user)
        end
      end

      it "does not paginate when there are too few" do
        visit "/users?letter=U"

        refute_match "Previous", page.body
        refute_match "Next", page.body
      end

      it "paginates forward only if on the first page" do
        visit "/users?letter=U&per_page=3"

        refute_match "Previous", page.body
        assert_match "Next", page.body
      end

      it "paginates backward only if on the last page" do
        u2 = Fabricate(:user, :username => "uzzzzz")

        visit "/users?letter=U&per_page=3"
        click_link "next_button"

        assert_match u2.username, page.body
        assert_match "Previous", page.body
        refute_match "Next", page.body
      end

      it "paginates forward and backward if on a middle page" do
        visit "/users?letter=U&per_page=2"

        click_link "next_button"

        assert_match "Previous", page.body
        assert_match "Next", page.body
      end
    end
  end
end
