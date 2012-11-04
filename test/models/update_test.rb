# encoding: utf-8
require_relative '../test_helper'

describe Update do
  include TestHelper

  describe "search" do
    describe "blank query" do
      before do
        20.times { |count| Fabricate(:update, :text => "This is update #{count}") }
      end

      it "returns all updates when the query is blank" do
        assert_equal 20, Update.search("", {:from => 0, :size => 20}).count
      end

      it "can paginate through all updates" do
        page_1_updates = Update.search("", {:from => 0, :size => 3})
        page_2_updates = Update.search("", {:from => 3, :size => 3})

        page_1_updates.wont_equal page_2_updates
      end
    end

    it "returns an update that matches the given query" do
      10.times { |count| Fabricate(:update, :text => "This is update #{count}") }
      Fabricate(:update, :text => "Something different to look for")
      10.times { |count| Fabricate(:update, :text => "This is update #{count+10}") }
      assert_equal 1, Update.basic_search("something different", {:from => 0, :size => 20}).count
    end

    it "returns updates that match the given query" do
      5.times { |count| Fabricate(:update, :text => "This is update #{count}") }
      3.times { |count| Fabricate(:update, :text => "Something else to look for") }
      15.times { |count| Fabricate(:update, :text => "This is update #{count}") }
      assert_equal 3, Update.basic_search("look for", {:from => 0, :size => 20}).count
    end
  end

  describe "text length" do
    it "is not valid without any text" do
      u = Fabricate.build(:update, :text => "")
      refute u.save, "I made an empty update, it's very zen."
    end

    it "is valid with one character" do
      u = Fabricate.build(:update, :text => "?")
      assert u.save
    end

    it "is not valid with > 140 characters" do
      u = Fabricate.build(:update, :text => "This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. jklol")
      refute u.save, "I made an update with over 140 characters"
    end
  end

  describe "@ replies" do
    describe "non existing user" do
      it "does not make links (before create)" do
        u = Fabricate.build(:update, :text => "This is a message mentioning @steveklabnik.")
        assert_match "This is a message mentioning @steveklabnik.", u.to_html
      end

      it "does not make links (after create)" do
        u = Fabricate(:update, :text => "This is a message mentioning @steveklabnik.")
        assert_match "This is a message mentioning @steveklabnik.", u.to_html
      end
    end

    describe "existing user" do
      before do
        Fabricate(:user, :username => "steveklabnik")
      end

      it "makes a link (before create)" do
        u = Fabricate.build(:update, :text => "This is a message mentioning @SteveKlabnik.")
        assert_match /\/users\/steveklabnik'>@SteveKlabnik<\/a>/, u.to_html
      end

      it "makes a link (after create)" do
        u = Fabricate(:update, :text => "This is a message mentioning @SteveKlabnik.")
        assert_match /\/users\/steveklabnik'>@SteveKlabnik<\/a>/, u.to_html
      end
    end

    describe "existing user with domain" do
      it "makes a link (before create)" do
        @author = Fabricate(:author, :username => "steveklabnik",
                                   :domain => "identi.ca",
                                   :remote_url => 'http://identi.ca/steveklabnik')
        u = Fabricate.build(:update, :text => "This is a message mentioning @SteveKlabnik@identi.ca.")
        assert_match /<a href='#{@author.url}'>@SteveKlabnik@identi.ca<\/a>/, u.to_html
      end

      it "makes a link (after create)" do
        @author = Fabricate(:author, :username => "steveklabnik",
                                   :domain => "identi.ca",
                                   :remote_url => 'http://identi.ca/steveklabnik')
        u = Fabricate(:update, :text => "This is a message mentioning @SteveKlabnik@identi.ca.")
        assert_match /<a href='#{@author.url}'>@SteveKlabnik@identi.ca<\/a>/, u.to_html
      end

      describe "mentioning a different user" do
        it "makes a link (before create)" do
          @mentioned = Fabricate(:author, :username => "chrismdp",
                              :domain => "rstat.us")
          @author = Fabricate(:author, :username => "steveklabnik",
                              :domain => "identi.ca",
                              :remote_url => 'http://identi.ca/steveklabnik')
          u = Fabricate.build(:update, :text => "This is a message mentioning @chrismdp@rstat.us.", :author => @author)
          assert_match %r{<a href='http://rstat.us/users/chrismdp'>@chrismdp@rstat.us<\/a>}, u.to_html
        end

      end
    end

    describe "existing user mentioned in the middle of the word" do
      before do
        Fabricate(:user, :username => "steveklabnik")
        Fabricate(:user, :username => "bar")
      end

      it "does not make a link (before create)" do
        u = Fabricate.build(:update, :text => "@SteveKlabnik @nobody foo@bar.wadus @SteveKlabnik")
        assert_match "\/users\/steveklabnik'>@SteveKlabnik<\/a> @nobody foo@bar.wadus <a href='http:\/\/#{u.author.domain}\/users\/steveklabnik'>@SteveKlabnik<\/a>", u.to_html
      end

      it "does not make a link (after create)" do
        u = Fabricate(:update, :text => "@SteveKlabnik @nobody foo@bar.wadus @SteveKlabnik")
        assert_match "\/users\/steveklabnik'>@SteveKlabnik<\/a> @nobody foo@bar.wadus <a href='http:\/\/#{u.author.domain}\/users\/steveklabnik'>@SteveKlabnik<\/a>", u.to_html
      end
    end
  end

  describe "links" do
    it "makes URLs into links (before create)" do
      u = Fabricate.build(:update, :text => "This is a message mentioning http://rstat.us/.")
      assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.to_html
      u = Fabricate.build(:update, :text => "https://github.com/hotsh/rstat.us/issues#issue/11")
      assert_equal "<a href='https://github.com/hotsh/rstat.us/issues#issue/11'>https://github.com/hotsh/rstat.us/issues#issue/11</a>", u.to_html
    end

    it "makes URLs into links (after create)" do
      u = Fabricate(:update, :text => "This is a message mentioning http://rstat.us/.")
      assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.to_html
      u = Fabricate(:update, :text => "https://github.com/hotsh/rstat.us/issues#issue/11")
      assert_equal "<a href='https://github.com/hotsh/rstat.us/issues#issue/11'>https://github.com/hotsh/rstat.us/issues#issue/11</a>", u.to_html
    end

    it "makes URLs in this edgecase into links" do
      edgecase = <<-EDGECASE
        Not perfect, but until there's an API, you can quick add text to your status using
        links like this: http://rstat.us/?status={status}
      EDGECASE
      u = Fabricate.build(:update, :text => edgecase)
      assert_match "<a href='http://rstat.us/?status={status}'>http://rstat.us/?status={status}</a>", u.to_html
    end
  end

  describe "hashtags" do
    it "makes links if hash starts a word (before create)" do
      u = Fabricate.build(:update, :text => "This is a message with a #hashtag.")
      assert_match /<a href='\/search\?search=%23hashtag'>#hashtag<\/a>/, u.to_html
      u = Fabricate.build(:update, :text => "This is a message with a#hashtag.")
      assert_equal "This is a message with a#hashtag.", u.to_html
    end

    it "makes links if hash starts a word (after create)" do
      u = Fabricate(:update, :text => "This is a message with a #hashtag.")
      assert_match /<a href='\/search\?search=%23hashtag'>#hashtag<\/a>/, u.to_html
      u = Fabricate(:update, :text => "This is a message with a#hashtag.")
      assert_equal "This is a message with a#hashtag.", u.to_html
    end

    it "makes links for both a hashtag and a URL (after create)" do
      u = Fabricate(:update, :text => "This is a message with a #hashtag and mentions http://rstat.us/.")

      assert_match /<a href='\/search\?search=%23hashtag'>#hashtag<\/a>/, u.to_html
      assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.to_html
    end

    it "extracts hashtags" do
      u = Fabricate(:update, :text => "#lots #of #hash #tags")
      assert_equal ["lots", "of", "hash", "tags"], u.tags
    end

    it "extracts hashtags when international symbols exist in hashtag" do
      u = Fabricate(:update, :text => "#Cantábrico is an international hashtag")
      assert_equal ["Cantábrico"], u.tags
    end

    it "makes links for international hashtag and a URL (after create)" do
      hashtag = "#Cantábrico"
      u = Fabricate(:update, :text => "This is a message with a #{hashtag}.")
      proper_link = "<a href='/search\?search=%23#{hashtag.gsub(/^#/, '')}'>#{hashtag}</a>"
      # Hacky method because MiniTest assert_match method insisted on escaping utf-8 characters within the regex
      assert( u.to_html.include?(proper_link),
            "#{u.to_html} does not match #{proper_link}")
    end
  end

  describe "twitter" do
    describe "twitter => true" do
      it "sets the tweeted flag" do
        u = Fabricate.build(:update, :text => "This is a message", :twitter => true)
        assert_equal true, u.twitter?
      end

      it "sends the update to twitter" do
        f = Fabricate(:feed)
        at = Fabricate(:author, :feed => f)
        u = Fabricate(:user, :author => at)
        a = Fabricate(:authorization, :user => u)
        Twitter.expects(:update)
        u.feed.updates << Fabricate.build(:update, :text => "This is a message", :twitter => true, :author => at)
        assert_equal u.twitter?, true
      end

      it "does not send to twitter if there's no twitter auth" do
        f = Fabricate(:feed)
        at = Fabricate(:author, :feed => f)
        u = Fabricate(:user, :author => at)
        Twitter.expects(:update).never
        u.feed.updates << Fabricate.build(:update, :text => "This is a message", :twitter => true, :author => at)
      end
    end

    describe "twitter => false (default)" do
      it "does not set the tweeted flag" do
        u = Fabricate.build(:update, :text => "This is a message.")
        assert_equal false, u.twitter?
      end

      it "does not send the update to twitter" do
        f = Fabricate(:feed)
        at = Fabricate(:author, :feed => f)
        u = Fabricate(:user, :author => at)
        a = Fabricate(:authorization, :user => u)
        Twitter.expects(:update).never
        u.feed.updates << Fabricate.build(:update, :text => "This is a message", :twitter => false, :author => at)
      end
    end
  end

  describe "same update twice in a row" do
    it "will not save if both are from the same user" do
      feed = Fabricate(:feed)
      author = Fabricate(:author, :feed => feed)
      user = Fabricate(:user, :author => author)
      update = Fabricate.build(:update, :text => "This is a message", :feed => author.feed, :author => author, :twitter => false)
      user.feed.updates << update
      user.feed.save
      user.save
      assert_equal 1, user.feed.updates.size
      update = Fabricate.build(:update, :text => "This is a message", :feed => author.feed, :author => author, :twitter => false)
      user.feed.updates << update
      refute update.valid?
    end

    it "will save if each are from different users" do
      feed1 = Fabricate(:feed)
      author1 = Fabricate(:author, :feed => feed1)
      user1 = Fabricate(:user, :author => author1)
      feed2 = Fabricate(:feed)
      author2 = Fabricate(:author, :feed => feed2)
      user2 = Fabricate(:user, :author => author2)
      update = Fabricate.build(:update, :text => "This is a message", :feed => author1.feed, :author => author1, :twitter => false)
      user1.feed.updates << update
      user1.feed.save
      user1.save
      assert_equal 1, user1.feed.updates.size
      update = Fabricate.build(:update, :text => "This is a message", :feed => author2.feed, :author => author2, :twitter => false)
      user1.feed.updates << update
      assert update.valid?
    end
  end
end
