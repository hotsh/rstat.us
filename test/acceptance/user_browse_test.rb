require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

class UserBrowseTest < MiniTest::Unit::TestCase

  include AcceptanceHelper

  def test_users_browse
    zebra    = Factory(:user, :username => "zebra")
    aardvark = Factory(:user, :username => "aardvark")
    a = Factory(:authorization, :user => aardvark)
    log_in(aardvark, a.uid)

    visit "/users"

    assert has_link? "aardvark"
    assert has_link? "zebra"
  end

  def test_users_browse_paginates
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    51.times do
      u2 = Factory(:user)
    end

    visit "/users"

    click_link "next_button"

    assert_match "Previous", page.body
    assert_match "Next", page.body
  end

  def test_users_browse_by_letter_paginates
    visit "/users"

    49.times do
      u2 = Factory(:user)
    end
    u2 = Factory(:user, :username => "uzzzzz")

    click_link "U"
    click_link "next_button"

    assert_match u2.username, page.body
  end

  def test_users_browse_shows_latest_users
    aardvark = Factory(:user, :username => "aardvark", :created_at => Date.new(2010, 10, 23))
    zebra    = Factory(:user, :username => "zebra", :created_at => Date.new(2011, 10, 24))
    a = Factory(:authorization, :user => aardvark)

    log_in(aardvark, a.uid)

    visit "/users"
    assert_match /zebra.*aardvark/m, page.body
  end

  def test_users_browse_by_letter
    alpha = Factory(:user, :username => "alpha")
    a = Factory(:authorization, :user => alpha)

    ["aardvark", "beta", "BANANAS"].each do |u|
      u2 = Factory(:user, :username => u)
    end

    log_in(alpha, a.uid)

    visit "/users"
    click_link "B"

    assert has_link? "(beta)"
    assert has_link? "(BANANAS)"
    refute_match "(aardvark)", page.body
  end

  def test_users_browse_by_non_letter
    alpha = Factory(:user, :username => "alpha")
    a = Factory(:authorization, :user => alpha)

    ["flop", "__FILE__"].each do |u|
      u2 = Factory(:user, :username => u)
    end

    log_in(alpha, a.uid)

    visit "/users"
    click_link "Other"

    assert has_link? "__FILE__"
    refute_match "flop", page.body
  end

  def test_users_browse_no_results
    alpha = Factory(:user, :username => "alpha")
    a = Factory(:authorization, :user => alpha)

    log_in(alpha, a.uid)

    visit "/users"
    click_link "B"

    assert_match "Sorry, no users that match.", page.body
  end
end
