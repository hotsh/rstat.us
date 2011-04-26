require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../test_helper'

class UpdateTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_0_minimum
    u = Factory.build(:update, :text => "")
    refute u.save, "I made an empty update, it's very zen."
  end

  def test_1_character_update
    u = Factory.build(:update, :text => "?")
    assert u.save
  end

  def test_140_limit
    u = Factory.build(:update, :text => "This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. jklol")
    refute u.save, "I made an update with over 140 characters"
  end

  def test_at_replies_with_not_existing_user
    u = Factory.build(:update, :text => "This is a message mentioning @steveklabnik.")
    assert_match "This is a message mentioning @steveklabnik.", u.to_html
  end

  def test_at_replies_with_not_existing_user_after_create
    u = Factory(:update, :text => "This is a message mentioning @steveklabnik.")
    assert_match "This is a message mentioning @steveklabnik.", u.html
  end

  def test_at_replies_with_existing_user
    Factory(:user, :username => "steveklabnik")
    u = Factory.build(:update, :text => "This is a message mentioning @SteveKlabnik.")
    assert_match /\/users\/steveklabnik'>@SteveKlabnik<\/a>/, u.to_html
  end

  def test_at_replies_with_existing_user_after_create
    Factory(:user, :username => "steveklabnik")
    u = Factory(:update, :text => "This is a message mentioning @SteveKlabnik.")
    assert_match /\/users\/steveklabnik'>@SteveKlabnik<\/a>/, u.html
  end

  def test_at_replies_with_existing_user_with_domain
    a = Factory(:author, :username => "steveklabnik", 
                         :domain => "identi.ca", 
                         :remote_url => 'http://identi.ca/steveklabnik')
    u = Factory.build(:update, :text => "This is a message mentioning @SteveKlabnik@identi.ca.")
    assert_match /<a href='#{a.url}'>@SteveKlabnik@identi.ca<\/a>/, u.to_html
  end

  def test_at_replies_with_existing_user_with_domain_after_create
    a = Factory(:author, :username => "steveklabnik", 
                         :domain => "identi.ca", 
                         :remote_url => 'http://identi.ca/steveklabnik')
    u = Factory(:update, :text => "This is a message mentioning @SteveKlabnik@identi.ca.")
    assert_match /<a href='#{a.url}'>@SteveKlabnik@identi.ca<\/a>/, u.html
  end

  def test_at_replies
    Factory(:user, :username => "steveklabnik")
    Factory(:user, :username => "bar")
    u = Factory.build(:update, :text => "@SteveKlabnik @nobody foo@bar.wadus @SteveKlabnik")
    assert_match "\/users\/steveklabnik'>@SteveKlabnik<\/a> @nobody foo@bar.wadus <a href='http:\/\/\/users\/steveklabnik'>@SteveKlabnik<\/a>", u.to_html
  end

  def test_at_replies_after_create
    Factory(:user, :username => "steveklabnik")
    Factory(:user, :username => "bar")
    u = Factory(:update, :text => "@SteveKlabnik @nobody foo@bar.wadus @SteveKlabnik")
    assert_match "\/users\/steveklabnik'>@SteveKlabnik<\/a> @nobody foo@bar.wadus <a href='http:\/\/\/users\/steveklabnik'>@SteveKlabnik<\/a>", u.html
  end

  def test_links
    u = Factory.build(:update, :text => "This is a message mentioning http://rstat.us/.")
    assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.to_html
    u = Factory.build(:update, :text => "https://github.com/hotsh/rstat.us/issues#issue/11")
    assert_equal "<a href='https://github.com/hotsh/rstat.us/issues#issue/11'>https://github.com/hotsh/rstat.us/issues#issue/11</a>", u.to_html
  end

  def test_links_after_create
    u = Factory(:update, :text => "This is a message mentioning http://rstat.us/.")
    assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.html
    u = Factory(:update, :text => "https://github.com/hotsh/rstat.us/issues#issue/11")
    assert_equal "<a href='https://github.com/hotsh/rstat.us/issues#issue/11'>https://github.com/hotsh/rstat.us/issues#issue/11</a>", u.html
  end

  def test_edgecase_links
    edgecase = <<-EDGECASE
      Not perfect, but until there's an API, you can quick add text to your status using
      links like this: http://rstat.us/?status={status}
    EDGECASE
    u = Factory.build(:update, :text => edgecase)
    assert_match "<a href='http://rstat.us/?status={status}'>http://rstat.us/?status={status}</a>", u.to_html
  end

  def test_hashtags
    u = Factory.build(:update, :text => "This is a message with a #hashtag.")
    assert_match /<a href='\/hashtags\/hashtag'>#hashtag<\/a>/, u.to_html
    u = Factory.build(:update, :text => "This is a message with a#hashtag.")
    assert_equal "This is a message with a#hashtag.", u.to_html
  end

  def test_hashtags_after_create
    u = Factory(:update, :text => "This is a message with a #hashtag.")
    assert_match /<a href='\/hashtags\/hashtag'>#hashtag<\/a>/, u.html
    u = Factory(:update, :text => "This is a message with a#hashtag.")
    assert_equal "This is a message with a#hashtag.", u.html
  end

  def test_html_exists_after_create
    u = Factory(:update, :text => "This is a message with a #hashtag and mentions http://rstat.us/.")
    assert_match /<a href='\/hashtags\/hashtag'>#hashtag<\/a>/, u.html
    assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.html
  end

  def test_language_is_stored
    u = Factory(:update, :text => "Als hadden geweest is, is hebben te laat.")
    assert_equal "dutch", u.language
  end

  def test_tags_are_extracted
    u = Factory(:update, :text => "#lots #of #hash #tags")
    assert_equal ["lots", "of", "hash", "tags"], u.tags
  end

  def test_hashtag_search
    u1 = Factory(:update, :text => "this has #lots #of #hash #tags")
    u2 = Factory(:update, :text => "this has #lots #of #hash #tags #also")
    search_results = Update.hashtag_search("lots", {:page => 1, :per_page => 2}).map do |update|
      update.id.to_s
    end
    assert_equal search_results.sort(), [u1.id.to_s, u2.id.to_s].sort()
  end

  def test_tweeted_flag_default
    u = Factory.build(:update, :text => "This is a message.")
    assert_equal false, u.twitter?
  end

  def test_tweeted_flag
    u = Factory.build(:update, :text => "This is a message", :twitter => true)
    assert_equal true, u.twitter?
  end

  def test_twitter_send
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    a = Factory(:authorization, :user => u)
    Twitter.expects(:update)
    u.feed.updates << Factory.build(:update, :text => "This is a message", :twitter => true, :facebook => false, :author => at)
    assert_equal u.twitter?, true
  end

  def test_no_twitter_send
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    a = Factory(:authorization, :user => u)
    Twitter.expects(:update).never
    u.feed.updates << Factory.build(:update, :text => "This is a message", :twitter => false, :facebook => false, :author => at)
  end

  def test_twitter_send_no_twitter_auth
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    Twitter.expects(:update).never
    u.feed.updates << Factory.build(:update, :text => "This is a message", :twitter => true, :facebook => false, :author => at)
  end

  def test_facebook_send
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    a = Factory(:authorization, :user => u, :provider => "facebook")
    FbGraph::User.expects(:me).returns(mock(:feed! => nil))
    u.feed.updates << Factory.build(:update, :text => "This is a message", :facebook => true, :twitter => false, :author => at)
  end

  def test_no_facebook_send
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    a = Factory(:authorization, :user => u, :provider => "facebook")
    FbGraph::User.expects(:me).never
    u.feed.updates << Factory.build(:update, :text => "This is a message", :facebook => false, :twitter => false, :author => at)
  end

  def test_facebook_send_no_facebook_auth
    f = Factory(:feed)
    at = Factory(:author, :feed => f)
    u = Factory(:user, :author => at, :feed => f)
    FbGraph::User.expects(:me).never
    u.feed.updates << Factory.build(:update, :text => "This is a message", :facebook => false, :twitter => false, :author => at)
  end
end
