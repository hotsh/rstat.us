require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "feeds" do
  include AcceptanceHelper

  it "redirects to the username's atom feed with the right case" do
    u = Fabricate(:user)
    visit "/users/#{u.username.upcase}/feed"
    current_url.must_match(/\/feeds\/#{u.feed.id}.atom$/)
  end

  it "404s if that username doesnt exist" do
    visit "/users/nonexistent/feed"
    assert_match "The page you were looking for doesn't exist.", page.body
  end

  it "404s if that feed id doesnt exist" do
    visit "/feeds/123"
    page.status_code.must_equal(404)
  end

  describe "atom for the hub" do
    it "returns 20 updates if no cache header info is supplied" do
      f = Fabricate(:feed)
      21.times do
        Fabricate(:update, :feed => f)
      end

      get "/feeds/#{f.id}.atom"
      if last_response.status == 301
        follow_redirect!
      end

      atom = Nokogiri.XML(last_response.body)
      entries = atom.xpath("//xmlns:entry")

      entries.length.must_equal(20)
    end

    it "returns updates respecting If-Modified-Since cache header if used" do
      f = Fabricate(:feed)
      later = Fabricate(:update, :feed => f, :created_at => 1.day.ago)
      earlier = Fabricate(:update, :feed => f, :created_at => 2.weeks.ago)

      if ENV["ENABLE_HTTPS"] == "yes"
        url = "https://www.example.com/feeds/#{f.id}.atom"
      else
        url = "http://www.example.com/feeds/#{f.id}.atom"
      end

      get url, {}, "HTTP_IF_MODIFIED_SINCE" => 3.days.ago.httpdate

      atom = Nokogiri.XML(last_response.body)
      entries = atom.xpath("//xmlns:entry")

      entries.length.must_equal(1)
      entries.first.at_xpath("xmlns:id").content.must_match(/#{later.id}/)
    end
  end
end