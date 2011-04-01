require_relative "test_helper"

class UpdateTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_0_minimum
    u = Update.new(:text => "")
    refute u.save, "I made an empty update, it's very zen."
  end

  def test_1_character_update
    u = Update.new(:text => "?")
    assert u.save
  end

  def test_140_limit
    u = Update.new(:text => "This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. jklol")
    refute u.save, "I made an update with over 140 characters"
  end

  def test_at_replies_with_not_existing_user
    u = Update.new(:text => "This is a message mentioning @steveklabnik.")
    assert_match "This is a message mentioning @steveklabnik.", u.to_html
  end
  
  def test_at_replies_with_not_existing_user_after_create
    u = Update.create(:text => "This is a message mentioning @steveklabnik.")
    assert_match "This is a message mentioning @steveklabnik.", u.html
  end

  def test_at_replies_with_existing_user
    Factory(:user, :username => "steveklabnik")
    u = Update.new(:text => "This is a message mentioning @SteveKlabnik.")
    assert_match /<a href='\/users\/steveklabnik'>@SteveKlabnik<\/a>/, u.to_html
  end
  
  def test_at_replies_with_existing_user_after_create
    Factory(:user, :username => "steveklabnik")
    u = Update.create(:text => "This is a message mentioning @SteveKlabnik.")
    assert_match /<a href='\/users\/steveklabnik'>@SteveKlabnik<\/a>/, u.html
  end

  def test_at_replies
    Factory(:user, :username => "steveklabnik")
    Factory(:user, :username => "bar")
    u = Update.new(:text => "@SteveKlabnik @nobody foo@bar.wadus @SteveKlabnik")
    assert_match "<a href='\/users\/steveklabnik'>@SteveKlabnik<\/a> @nobody foo@bar.wadus <a href='\/users\/steveklabnik'>@SteveKlabnik<\/a>", u.to_html
  end
  
  def test_at_replies_after_create
    Factory(:user, :username => "steveklabnik")
    Factory(:user, :username => "bar")
    u = Update.create(:text => "@SteveKlabnik @nobody foo@bar.wadus @SteveKlabnik")
    assert_match "<a href='\/users\/steveklabnik'>@SteveKlabnik<\/a> @nobody foo@bar.wadus <a href='\/users\/steveklabnik'>@SteveKlabnik<\/a>", u.html
  end

  def test_links
    u = Update.new(:text => "This is a message mentioning http://rstat.us/.")
    assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.to_html
    u = Update.new(:text => "https://github.com/hotsh/rstat.us/issues#issue/11")
    assert_equal "<a href='https://github.com/hotsh/rstat.us/issues#issue/11'>https://github.com/hotsh/rstat.us/issues#issue/11</a>", u.to_html
  end
  
  def test_links_after_create
    u = Update.create(:text => "This is a message mentioning http://rstat.us/.")
    assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.html
    u = Update.create(:text => "https://github.com/hotsh/rstat.us/issues#issue/11")
    assert_equal "<a href='https://github.com/hotsh/rstat.us/issues#issue/11'>https://github.com/hotsh/rstat.us/issues#issue/11</a>", u.html
  end

  def test_edgecase_links
    edgecase = <<-EDGECASE
      Not perfect, but until there's an API, you can quick add text to your status using
      links like this: http://rstat.us/?status={status}
    EDGECASE
    u = Update.new(:text => edgecase)
    assert_match "<a href='http://rstat.us/?status={status}'>http://rstat.us/?status={status}</a>", u.to_html
  end

  def test_hashtags
    u = Update.new(:text => "This is a message with a #hashtag.")
    assert_match /<a href='\/hashtags\/hashtag'>#hashtag<\/a>/, u.to_html
    u = Update.new(:text => "This is a message with a#hashtag.")
    assert_equal "This is a message with a#hashtag.", u.to_html
  end

  def test_hashtags_after_create
    u = Update.create(:text => "This is a message with a #hashtag.")
    assert_match /<a href='\/hashtags\/hashtag'>#hashtag<\/a>/, u.html
    u = Update.create(:text => "This is a message with a#hashtag.")
    assert_equal "This is a message with a#hashtag.", u.html
  end

  def test_html_exists_after_create
    u = Update.create(:text => "This is a message with a #hashtag and mentions http://rstat.us/.")
    assert_match /<a href='\/hashtags\/hashtag'>#hashtag<\/a>/, u.html
    assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.html
  end
  
  def test_language_is_stored
    u = Update.create(:text => "Als hadden geweest is, is hebben te laat.")
    assert_equal "dutch", u.language
  end
  
  def test_tags_are_extracted
    u = Update.create(:text => "#lots #of #hash #tags")
    assert_equal ["lots", "of", "hash", "tags"], u.tags
  end
  
  def test_hashtag_search
    u1 = Update.create(:text => "this has #lots #of #hash #tags")
    u2 = Update.create(:text => "this has #lots #of #hash #tags #also")
    search_results = Update.hashtag_search("lots", {:page => 1, :per_page => 2}).map do |update|
      update.id.to_s
    end
    assert_equal search_results.sort(), [u1.id.to_s, u2.id.to_s].sort()
  end

  def test_tweeted_flag_default
    u = Update.new(:text => "This is a message.")
    assert_equal false, u.twitter?
  end

  def test_tweeted_flag
    u = Update.new(:text => "This is a message", :twitter => true)
    assert_equal true, u.twitter?
  end
  
  def test_twitter_send
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    a = Factory(:authorization, :user => u)
    Twitter.expects(:update)
    u.feed.updates << Update.new(:text => "This is a message", :twitter => true, :facebook => false, :author => at)
    assert_equal u.twitter?, true
  end
  
  def test_no_twitter_send
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    a = Factory(:authorization, :user => u)
    Twitter.expects(:update).never
    u.feed.updates << Update.new(:text => "This is a message", :twitter => false, :facebook => false, :author => at)
  end
  
  def test_twitter_send_no_twitter_auth
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    Twitter.expects(:update).never
    u.feed.updates << Update.new(:text => "This is a message", :twitter => true, :facebook => false, :author => at)
  end
  
  def test_facebook_send
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    a = Factory(:authorization, :user => u, :provider => "facebook")
    FbGraph::User.expects(:me).returns(mock(:feed! => nil))
    u.feed.updates << Update.new(:text => "This is a message", :facebook => true, :twitter => false, :author => at)
  end
  
  def test_no_facebook_send
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    a = Factory(:authorization, :user => u, :provider => "facebook")
    FbGraph::User.expects(:me).never
    u.feed.updates << Update.new(:text => "This is a message", :facebook => false, :twitter => false, :author => at)
  end
  
  def test_facebook_send_no_facebook_auth
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    FbGraph::User.expects(:me).never
    u.feed.updates << Update.new(:text => "This is a message", :facebook => false, :twitter => false, :author => at)
  end

  def test_twitter_user_sees_Post_to_message
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :provider => "twitter")
    log_in(u, a.uid)
    visit "/updates"

    assert_match page.body, /Post to/
  end

  def test_facebook_user_sees_Post_to_message
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :provider => "facebook")
    log_in_fb(u, a.uid)
    visit "/updates"

    assert_match page.body, /Post to/
  end
  
  def test_email_user_sees_no_Post_to_message
    u = Factory(:user)
    log_in_email(u)
    visit "/updates"

    refute_match page.body, /Post to/
  end  
end
