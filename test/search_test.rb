require_relative "test_helper"

class FeedTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_search_link_renders_while_logged_in
    u = Factory(:user, :email => "some@email.com", :hashed_password => "blerg")
    log_in_email(u)

    visit "/"

    assert has_link? "Search Updates"
  end

  def test_anons_can_access_search
    visit "/search"

    assert_equal 200, page.status_code
    assert_match "/search", page.current_url
  end

  def test_search_actually_searches #we aren't logging in so this test also shows anons can use search
    s = Update.new(:text => "These aren't the droids you're looking for!")
    s.save

    visit "/search"

    fill_in "q", :with => "droids"
    click_button "Search"

    assert_match "These aren't the droids you're looking for!", page.body
  end

end
