require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "update" do
  include AcceptanceHelper

  it "goes to one update's page" do
    u = Fabricate(:update)
    visit "/updates/#{u.id}"

    within ".update .update-text" do
      assert has_content?(u.text)
    end
  end

  it "404s if the update does not exist" do
    visit "/updates/9000"
    page.status_code.must_equal(404)
  end
end