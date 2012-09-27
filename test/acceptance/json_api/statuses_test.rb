require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "JSON get statos" do
  include AcceptanceHelper
  
  it "returns the update" do
    log_in_as_some_user
    status = Fabricate(:update)
    visit "/api/statuses/show/#{status.id}.json"
    parsed_json = JSON.parse(source)
    parsed_json["text"].must_equal(status.text)
  end
end
