require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "Webfinger" do
  include AcceptanceHelper

  before do
    @user = Fabricate(:user)
    @user_webfinger_subject = "acct:#{@user.username}@#{@user.author.domain}"
  end

  it "404s if that user doesnt exist" do
    get "/users/acct:nonexistent@somedomain.com/xrd.xml"
    last_response.status.must_equal(404)
  end

  def webfinger_subject(param)
    get "/users/#{param}/xrd.xml"

    xml = Nokogiri.XML(last_response.body)
    xml.xpath("//xmlns:Subject").first.content
  end

  it "can find the user if the url has acct:username@domain" do
    param = "acct:#{@user.username}@#{@user.author.domain}"
    webfinger_subject(param).must_equal(@user_webfinger_subject)
  end

  it "can find the user if the url has acct:username" do
    param = "acct:#{@user.username}"
    webfinger_subject(param).must_equal(@user_webfinger_subject)
  end

  it "can find the user if the url has username@domain" do
    param = "#{@user.username}@#{@user.author.domain}"
    webfinger_subject(param).must_equal(@user_webfinger_subject)
  end

  it "can find the user if the url has username" do
    param = @user.username
    webfinger_subject(param).must_equal(@user_webfinger_subject)
  end
end