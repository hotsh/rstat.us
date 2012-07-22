require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "Salmon" do
  include AcceptanceHelper

  it "404s if that feed doesnt exist" do
    visit "/feeds/nonexistent/salmon"
    page.status_code.must_equal(404)
  end

  it "404s if there is no request body" do
    feed = Fabricate(:feed)
    visit "/feeds/#{feed.id}/salmon"
    page.status_code.must_equal(404)
  end

  it "404s if the request body does not contain a magic envelope" do
    feed = Fabricate(:feed)
    post "/feeds/#{feed.id}/salmon", "<?xml version='1.0' encoding='UTF-8'?><bogus-xml />"
    if last_response.status == 301
      follow_redirect!
    end

    last_response.status.must_equal(404)
  end
end