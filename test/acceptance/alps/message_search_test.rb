require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "Unauthenticated reading" do
  include AcceptanceHelper

  it "can transition to the search page from the homepage" do
    visit "/"
    assert has_selector?(:xpath, "//a[contains(@rel, 'messages-search')]")
  end
end