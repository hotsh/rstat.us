# encoding: UTF-8
require_relative '../test_helper'
require "webmock"
include WebMock::API

describe User do
  include TestHelper

  def stub_superfeedr_request_for_user(user)
    user_feed_url = CGI.escape(user.feed.url(:format => :atom))

    # Downcase the escaped user_feed_url for ruby 1.9.2
    stub_request(:post, "http://rstatus.superfeedr.com/").
      with(:body => "hub.mode=publish&hub.url=#{user_feed_url.downcase}",
           :headers => { 'Accept' => '*/*',
                         'Content-Type' => 'application/x-www-form-urlencoded',
                         'User-Agent' => 'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})

    # Leave the escaped user_feed_url as it is for ruby 1.9.3
    stub_request(:post, "http://rstatus.superfeedr.com/").
      with(:body => "hub.mode=publish&hub.url=#{user_feed_url}",
           :headers => { 'Accept' => '*/*',
                         'Content-Type' => 'application/x-www-form-urlencoded',
                         'User-Agent' => 'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})
  end

  describe "#at_replies" do
    it "returns all at_replies for this user" do
      u = Fabricate(:user, :username => "steve")
      update = Fabricate(:update, :text => "@steve oh hai!")
      Fabricate(:update, :text => "just some other update")

      assert_equal 1, u.at_replies.count
      assert_equal update.id, u.at_replies.first.id
    end

    it "returns all at_replies for a username containing ." do
      u = Fabricate(:user, :username => "hello.there")
      u1 = Fabricate(:user, :username => "helloothere")
      update = Fabricate(:update, :text => "@hello.there how _you_ doin'?")

      assert_equal 1, u.at_replies.count
      assert_equal 0, u1.at_replies.count
    end
  end

  describe "username" do
    it "can be changed" do
      u = Fabricate(:user)

      stub_superfeedr_request_for_user u

      u.update_profile!(:username => 'foobar')
      assert_equal 'foobar', u.username
    end

    it "must be unique" do
      Fabricate(:user, :username => "steve")
      u = Fabricate.build(:user, :username => "steve")
      refute u.save
    end

    it "must be unique regardless of case" do
      Fabricate(:user, :username => "steve")
      u = Fabricate.build(:user, :username => "Steve")
      refute u.save
    end

    it "must not be long" do
      u = Fabricate.build(:user, :username => "burningTyger_will_fail_with_this_username")
      refute u.save
    end

    it "must not contain special chars" do
      ["something@something.com", "another'quirk", ".boundary_case.", "another..case", "another/random\\test", "yet]another", ".Ὁμηρος", "I have spaces"].each do |i|
        u = Fabricate.build(:user, :username => i)
        refute u.save, "contains restricted characters."
      end
      ["Ὁμηρος"].each do |i|
        u = Fabricate.build(:user, :username => i)
        assert u.save, "characters being restricted unintentionally."
      end
    end

    it "must not be empty" do
      u = Fabricate.build(:user, :username => "")
      refute u.save, "blank username"
    end

    it "must not be nil" do
      u = Fabricate.build(:user, :username => nil)
      refute u.save, "nil username"
    end
  end

  describe "twitter auth" do
    it "has twitter" do
      u = Fabricate(:user)
      a = Fabricate(:authorization, :user => u)
      assert u.twitter?
    end

    it "returns twitter" do
      u = Fabricate(:user)
      a = Fabricate(:authorization, :user => u)
      assert_equal a, u.twitter
    end
  end

  describe "email" do
    it "can be changed" do
      u = Fabricate(:user)

      stub_superfeedr_request_for_user u

      u.update_profile!(:email => 'team@jackhq.com')
      refute u.email_confirmed
    end

    it "does not change email" do
      u = Fabricate(:user)
      assert_nil u.email_confirmed
    end
  end

  describe "perishable token" do
    it "sets the token" do
      u = Fabricate(:user)
      assert_nil u.perishable_token
      u.create_token
      refute_nil u.perishable_token
    end

    it "resets the token" do
      u = Fabricate(:user)
      u.create_token
      refute_nil u.perishable_token
      refute_nil u.perishable_token_set
      u.reset_perishable_token
      assert_nil u.perishable_token
      assert_nil u.perishable_token_set
    end
  end

  describe "#reset_password" do
    it "changes the password" do
      u = Fabricate(:user)
      u.password = "test_password"
      u.save
      prev_pass = u.hashed_password
      u.reset_password("password")
      assert u.hashed_password != prev_pass
    end
  end

  describe "email confirmation" do
    it "has an unconfirmed email initially" do
      u = Fabricate(:user)
      assert_nil u.email_confirmed
    end

    it "changes email and requires reconfirmation" do
      u = Fabricate(:user)

      stub_superfeedr_request_for_user u

      u.update_profile!(:email => 'team@jackhq.com')
      u.save
      refute u.email_confirmed
    end

    it "allows unconfirmed emails to be entered more than once" do
      u = Fabricate(:user)

      stub_superfeedr_request_for_user u

      u.update_profile!(:email => 'team@jackhq.com')

      u2 = Fabricate(:user)
      u2.email = 'team@jackhq.com'
      assert u2.valid?
    end

    it "does not allow confirmed emails to be entered more than once" do
      u = Fabricate(:user)
      stub_superfeedr_request_for_user u
      u.update_profile!(:email => 'team@jackhq.com')
      u.email_confirmed = true
      u.save

      u2 = Fabricate(:user)
      stub_superfeedr_request_for_user u2
      u2.update_profile!(:email => 'team@jackhq.com')

      refute u2.valid?
    end
  end

  describe "following" do
    describe "local users" do
      before do
        @u = Fabricate(:user)
        @u2 = Fabricate(:user)
      end

      describe "#follow!" do
        it "adds the followee's feed to the follower's following list" do
          @u.follow!(@u2.feed)
          @u.following.must_include(@u2.feed)
        end

        it "adds the follower's feed to the followee's followers list" do
          @u.follow!(@u2.feed)
          @u2.reload
          @u2.followers.must_include(@u.feed)
        end

        it "does nothing if already following" do
          @u.follow!(@u2.feed)
          @u.follow!(@u2.feed)
          @u2.reload
          @u.following.count.must_equal(1)
          @u2.followers.count.must_equal(1)
        end
      end

      describe "#unfollow!" do
        it "removes the followee's feed from the follower's following list" do
          @u.follow!(@u2.feed)
          @u.unfollow!(@u2.feed)
          @u.following.wont_include(@u2.feed)
        end

        it "removes the follower's feed from the followee's followers list" do
          @u.follow!(@u2.feed)
          @u.unfollow!(@u2.feed)
          @u2.reload
          @u2.followers.wont_include(@u.feed)
        end

        it "does nothing if already not following" do
          @u.unfollow!(@u2.feed)
          @u2.reload
          @u.following.count.must_equal(0)
          @u2.followers.count.must_equal(0)
        end
      end

      describe "followed_by?" do
        it "is true if the feed is following this user" do
          @u.follow!(@u2.feed)
          @u2.reload
          assert @u2.followed_by?(@u.feed)
        end

        it "is false if the feed is not following this user" do
          refute @u2.followed_by?(@u.feed)
        end
      end
    end
  end

  describe "#timeline" do
    it "includes my updates" do
      u = Fabricate(:user)

      my_update = Fabricate(:update, :text => "this is my update", :author => u.author)
      u.feed.updates << my_update

      assert u.timeline.include? my_update
    end

    it "includes updates from users i'm following" do
      u = Fabricate(:user)
      u2 = Fabricate(:user)

      u.follow! u2.feed

      u2_update = Fabricate(:update, :text => "this is your update", :author => u2.author)
      u2.feed.updates << u2_update

      assert u.timeline.include? u2_update
    end

    it "does not include updates from users i'm not following" do
      u = Fabricate(:user)
      u2 = Fabricate(:user)

      u2_update = Fabricate(:update, :text => "this is your update", :author => u2.author)
      u2.feed.updates << u2_update

      refute u.timeline.include? u2_update
    end
  end

  describe "#autocomplete" do
    before do
      @bob = Fabricate(:user, :username => "bob")
      @rob = Fabricate(:user, :username => "rob")
      @bob.follow!(@rob.feed)
    end

    it "returns a followed user starting with query" do
      @result = @bob.autocomplete('r')
      assert_equal @rob.username, @result.first[:label]
    end

    it "returns a followed user if we use a different case" do
      @result = @bob.autocomplete('R')
      assert_equal @rob.username, @result.first[:label]
    end

    it "returns an empty array if query is nil" do
      @result = @bob.autocomplete(nil)
      assert_equal [], @result
    end

    it "returns an empty array if query is blank" do
      @result = @bob.autocomplete('')
      assert_equal [], @result
    end

    it "returns an empty array if query is not matched" do
      @result = @bob.autocomplete('ta')
      assert_equal [], @result
    end

    it "escapes special characters" do
      @result = @bob.autocomplete('r+(')
      assert_equal [], @result
    end
  end

  describe "self#find_by_case_insensitive_username" do
    before do
      @u = Fabricate(:user, :username => "oMg")
    end

    it "returns the user if we use the same case" do
      assert_equal @u, User.find_by_case_insensitive_username("oMg")
    end

    it "returns the user if we use a different case" do
      assert_equal @u, User.find_by_case_insensitive_username("OmG")
    end

    it "returns nil if no user matches" do
      assert_equal nil, User.find_by_case_insensitive_username("blah")
    end

    it "escapes regex chars so that regexing isnt allowed" do
      assert_equal nil, User.find_by_case_insensitive_username(".mg")
    end
  end

  describe "accounts that only have twitter auth, no password" do
    it "should not error if you try to log in with a password" do
      u = Fabricate(:user)

      # This is contrived; users should no longer end up in this state.
      u.update_attribute(:hashed_password, nil)

      # Issue #532 is this throwing a BCrypt::Errors::InvalidHash exception;
      # the correct behavior is returning nil.
      authenticated_user = User.authenticate(u.username, "anything")

      assert authenticated_user.nil?
    end
  end
end
