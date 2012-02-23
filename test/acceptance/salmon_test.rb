require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "Salmon" do
  include AcceptanceHelper

  it "404s if that feed doesnt exist" do
    visit "/feeds/nonexistent/salmon"
    page.status_code.must_equal(404)
  end

  it "404s if the request body does not contain a magic envelope" do
    feed = Fabricate(:feed)
    page.driver.post "/feeds/#{feed.id}/salmon", "<?xml version='1.0' encoding='UTF-8'?><bogus-xml />"
    page.status_code.must_equal(404)
  end
end