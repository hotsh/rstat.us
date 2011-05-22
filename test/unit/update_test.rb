require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../test_helper'

describe Update do

  include TestHelper

  describe "text length" do
    it "is not valid without any text" do
      u = Factory.build(:update, :text => "")
      refute u.save, "I made an empty update, it's very zen."
    end

    it "is valid with one character" do
      u = Factory.build(:update, :text => "?")
      assert u.save
    end

    it "is not valid with > 140 characters" do
      u = Factory.build(:update, :text => "This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. jklol")
      refute u.save, "I made an update with over 140 characters"
    end
  end

  describe "@ replies" do
    describe "non existing user" do
      it "does not make links (before create)" do
        u = Factory.build(:update, :text => "This is a message mentioning @steveklabnik.")
        assert_match "This is a message mentioning @steveklabnik.", u.to_html
      end

      it "does not make links (after create)" do
        u = Factory(:update, :text => "This is a message mentioning @steveklabnik.")
        assert_match "This is a message mentioning @steveklabnik.", u.html
      end
    end

    describe "existing user" do
      before do
        Factory(:user, :username => "steveklabnik")
      end

      it "makes a link (before create)" do
        u = Factory.build(:update, :text => "This is a message mentioning @SteveKlabnik.")
        assert_match /\/users\/steveklabnik'>@SteveKlabnik<\/a>/, u.to_html
      end

      it "makes a link (after create)" do
        u = Factory(:update, :text => "This is a message mentioning @SteveKlabnik.")
        assert_match /\/users\/steveklabnik'>@SteveKlabnik<\/a>/, u.html
      end
    end

    describe "existing user with domain" do
      before do
        @a = Factory(:author, :username => "steveklabnik",
                             :domain => "identi.ca",
                             :remote_url => 'http://identi.ca/steveklabnik')
      end

      it "makes a link (before create)" do
        u = Factory.build(:update, :text => "This is a message mentioning @SteveKlabnik@identi.ca.")
        assert_match /<a href='#{@a.url}'>@SteveKlabnik@identi.ca<\/a>/, u.to_html
      end

      it "makes a link (after create)" do
        u = Factory(:update, :text => "This is a message mentioning @SteveKlabnik@identi.ca.")
        assert_match /<a href='#{@a.url}'>@SteveKlabnik@identi.ca<\/a>/, u.html
      end
    end

    describe "existing user mentioned in the middle of the word" do
      before do
        Factory(:user, :username => "steveklabnik")
        Factory(:user, :username => "bar")
      end

      it "does not make a link (before create)" do
        u = Factory.build(:update, :text => "@SteveKlabnik @nobody foo@bar.wadus @SteveKlabnik")
        assert_match "\/users\/steveklabnik'>@SteveKlabnik<\/a> @nobody foo@bar.wadus <a href='http:\/\/#{u.author.domain}\/users\/steveklabnik'>@SteveKlabnik<\/a>", u.to_html
      end

      it "does not make a link (after create)" do
        u = Factory(:update, :text => "@SteveKlabnik @nobody foo@bar.wadus @SteveKlabnik")
        assert_match "\/users\/steveklabnik'>@SteveKlabnik<\/a> @nobody foo@bar.wadus <a href='http:\/\/#{u.author.domain}\/users\/steveklabnik'>@SteveKlabnik<\/a>", u.html
      end
    end
  end

  describe "links" do
    it "makes URLs into links (before create)" do
      u = Factory.build(:update, :text => "This is a message mentioning http://rstat.us/.")
      assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.to_html
      u = Factory.build(:update, :text => "https://github.com/hotsh/rstat.us/issues#issue/11")
      assert_equal "<a href='https://github.com/hotsh/rstat.us/issues#issue/11'>https://github.com/hotsh/rstat.us/issues#issue/11</a>", u.to_html
    end

    it "makes URLs into links (after create)" do
      u = Factory(:update, :text => "This is a message mentioning http://rstat.us/.")
      assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.html
      u = Factory(:update, :text => "https://github.com/hotsh/rstat.us/issues#issue/11")
      assert_equal "<a href='https://github.com/hotsh/rstat.us/issues#issue/11'>https://github.com/hotsh/rstat.us/issues#issue/11</a>", u.html
    end

    it "makes URLs in this edgecase into links" do
      edgecase = <<-EDGECASE
        Not perfect, but until there's an API, you can quick add text to your status using
        links like this: http://rstat.us/?status={status}
      EDGECASE
      u = Factory.build(:update, :text => edgecase)
      assert_match "<a href='http://rstat.us/?status={status}'>http://rstat.us/?status={status}</a>", u.to_html
    end
  end

  describe "hashtags" do
    it "makes links if hash starts a word (before create)" do
      u = Factory.build(:update, :text => "This is a message with a #hashtag.")
      assert_match /<a href='\/hashtags\/hashtag'>#hashtag<\/a>/, u.to_html
      u = Factory.build(:update, :text => "This is a message with a#hashtag.")
      assert_equal "This is a message with a#hashtag.", u.to_html
    end

    it "makes links if hash starts a word (after create)" do
      u = Factory(:update, :text => "This is a message with a #hashtag.")
      assert_match /<a href='\/hashtags\/hashtag'>#hashtag<\/a>/, u.html
      u = Factory(:update, :text => "This is a message with a#hashtag.")
      assert_equal "This is a message with a#hashtag.", u.html
    end

    it "makes links for both a hashtag and a URL (after create)" do
      u = Factory(:update, :text => "This is a message with a #hashtag and mentions http://rstat.us/.")
      assert_match /<a href='\/hashtags\/hashtag'>#hashtag<\/a>/, u.html
      assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.html
    end

    it "extracts hashtags" do
      u = Factory(:update, :text => "#lots #of #hash #tags")
      assert_equal ["lots", "of", "hash", "tags"], u.tags
    end

    it "can search by hashtag" do
      u1 = Factory(:update, :text => "this has #lots #of #hash #tags")
      u2 = Factory(:update, :text => "this has #lots #of #hash #tags #also")
      search_results = Update.hashtag_search("lots", {:page => 1, :per_page => 2}).map do |update|
        update.id.to_s
      end
      assert_equal search_results.sort(), [u1.id.to_s, u2.id.to_s].sort()
    end

    it "can filter by hashtag" do
      update = Factory(:update, :text => "mother-effing #hashtags")
      Factory(:update, :text => "just some other update")

      assert_equal 1, Update.hashtag_search("hashtags", {}).length
      assert_equal update.id, Update.hashtag_search("hashtags", {}).first.id
    end
  end

  it "stores the language" do
    u = Factory(:update, :text => "Als hadden geweest is, is hebben te laat.")
    assert_equal "dutch", u.language
  end

  describe "twitter" do
    describe "twitter => true" do
      it "sets the tweeted flag" do
        u = Factory.build(:update, :text => "This is a message", :twitter => true)
        assert_equal true, u.twitter?
      end

      it "sends the update to twitter" do
        f = Factory(:feed)
        at = Factory(:author, :feed => f)
        u = Factory(:user, :author => at)
        a = Factory(:authorization, :user => u)
        Twitter.expects(:update)
        u.feed.updates << Factory.build(:update, :text => "This is a message", :twitter => true, :facebook => false, :author => at)
        assert_equal u.twitter?, true
      end

      it "does not send to twitter if there's no twitter auth" do
        f = Factory(:feed)
        at = Factory(:author, :feed => f)
        u = Factory(:user, :author => at)
        Twitter.expects(:update).never
        u.feed.updates << Factory.build(:update, :text => "This is a message", :twitter => true, :facebook => false, :author => at)
      end
    end

    describe "twitter => false (default)" do
      it "does not set the tweeted flag" do
        u = Factory.build(:update, :text => "This is a message.")
        assert_equal false, u.twitter?
      end

      it "does not send the update to twitter" do
        f = Factory(:feed)
        at = Factory(:author, :feed => f)
        u = Factory(:user, :author => at)
        a = Factory(:authorization, :user => u)
        Twitter.expects(:update).never
        u.feed.updates << Factory.build(:update, :text => "This is a message", :twitter => false, :facebook => false, :author => at)
      end
    end
  end

  describe "facebook" do
    describe "facebook => true" do
      it "sends the update to facebook" do
        f = Factory(:feed)
        at = Factory(:author, :feed => f)
        u = Factory(:user, :author => at)
        a = Factory(:authorization, :user => u, :provider => "facebook")
        FbGraph::User.expects(:me).returns(mock(:feed! => nil))
        u.feed.updates << Factory.build(:update, :text => "This is a message", :facebook => true, :twitter => false, :author => at)
      end

      it "does not send the update to facebook if no facebook auth" do
        f = Factory(:feed)
        at = Factory(:author, :feed => f)
        u = Factory(:user, :author => at)
        FbGraph::User.expects(:me).never
        u.feed.updates << Factory.build(:update, :text => "This is a message", :facebook => true, :twitter => false, :author => at)
      end
    end

    describe "facebook => false" do
      it "does not send the update to facebook" do
        f = Factory(:feed)
        at = Factory(:author, :feed => f)
        u = Factory(:user, :author => at)
        a = Factory(:authorization, :user => u, :provider => "facebook")
        FbGraph::User.expects(:me).never
        u.feed.updates << Factory.build(:update, :text => "This is a message", :facebook => false, :twitter => false, :author => at)
      end
    end
  end

  describe "same update twice in a row" do
    it "will not save if both are from the same user" do
      feed = Factory(:feed)
      author = Factory(:author, :feed => feed)
      user = Factory(:user, :author => author)
      update = Factory.build(:update, :text => "This is a message", :author => author, :twitter => false, :facebook => false)
      user.feed.updates << update
      user.feed.save
      user.save
      assert_equal 1, user.feed.updates.size
      update = Factory.build(:update, :text => "This is a message", :author => author, :twitter => false, :facebook => false)
      user.feed.updates << update
      refute update.valid?, "You already posted this update"
    end

    it "will save if each are from different users" do
      feed1 = Factory(:feed)
      author1 = Factory(:author, :feed => feed1)
      user1 = Factory(:user, :author => author1)
      feed2 = Factory(:feed)
      author2 = Factory(:author, :feed => feed2)
      user2 = Factory(:user, :author => author2)
      update = Factory.build(:update, :text => "This is a message", :author => author1, :twitter => false, :facebook => false)
      user1.feed.updates << update
      user1.feed.save
      user1.save
      assert_equal 1, user1.feed.updates.size
      update = Factory.build(:update, :text => "This is a message", :author => author2, :twitter => false, :facebook => false)
      user1.feed.updates << update
      assert update.valid?
    end
  end
end
