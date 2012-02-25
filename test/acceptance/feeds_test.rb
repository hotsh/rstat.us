require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "feeds" do
  include AcceptanceHelper

  it "redirects to the username's atom feed with the right case" do
    u = Fabricate(:user)
    url = "http://www.example.com/feeds/#{u.feed.id}.atom"
    visit "/users/#{u.username.upcase}/feed"
    assert_equal url, page.current_url
  end

  it "404s if that username doesnt exist" do
    visit "/users/nonexistent/feed"
    assert_match "The page you were looking for doesn't exist.", page.body
  end

  describe "atom for the hub" do
    it "returns 20 updates if no cache header info is supplied" do
      f = Fabricate(:feed)
      21.times do
        Fabricate(:update, :feed => f)
      end

      get "/feeds/#{f.id}.atom"
      atom = Nokogiri.XML(last_response.body)
      entries = atom.xpath("//xmlns:entry")

      entries.length.must_equal(20)
    end
  end
end