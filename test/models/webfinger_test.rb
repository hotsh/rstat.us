require_relative '../test_helper'

describe "Webfinger" do
  include TestHelper

  describe "#find_user" do
    before do
      @user = Fabricate(:user)
    end

    it "returns nil if it can't find the user" do
      refute Webfinger.find_user("acct:nada@rstat.us")
    end

    it "can find the user with acct:username@domain" do
      param = "acct:#{@user.username}@#{@user.author.domain}"
      Webfinger.find_user(param).must_equal(@user)
    end

    it "can find the user with acct:username" do
      param = "acct:#{@user.username}"
      Webfinger.find_user(param).must_equal(@user)
    end

    it "can find the user with username@domain" do
      param = "#{@user.username}@#{@user.author.domain}"
      Webfinger.find_user(param).must_equal(@user)
    end

    it "can find the user with username" do
      param = @user.username
      Webfinger.find_user(param).must_equal(@user)
    end
  end
end