require_relative "test_helper"

class UpdateTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_140_limit
    u = Update.new(:text => "This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. jklol")
    refute u.save, "I made an update with over 140 characters"
  end

  def test_at_replies
    u = Update.new(:text => "This is a message mentioning @steveklabnik.")
    assert_match /<a href='\/users\/steveklabnik'>@steveklabnik<\/a>/, u.to_html
  end

  def test_links
    u = Update.new(:text => "This is a message mentioning http://rstat.us/.")
    assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.to_html
  end

end
