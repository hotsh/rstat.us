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

    it "returns updates respecting If-Modified-Since cache header if used" do
      f = Fabricate(:feed)
      later = Fabricate(:update, :feed => f, :created_at => 1.day.ago)
      earlier = Fabricate(:update, :feed => f, :created_at => 2.weeks.ago)

      get "/feeds/#{f.id}.atom", {}, "HTTP_IF_MODIFIED_SINCE" => 3.days.ago.httpdate
      atom = Nokogiri.XML(last_response.body)
      entries = atom.xpath("//xmlns:entry")

      entries.length.must_equal(1)
      entries.first.at_xpath("xmlns:id").content.must_match(/#{later.id}/)
    end
  end
end