require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "Message searching" do
  include AcceptanceHelper

  it "can transition to the search page from the homepage" do
    visit "/"
    assert has_selector?(:xpath, "//a[contains(@rel, 'messages-search')]")
  end

  it "has a form with the right attributes and input" do
    visit "/"
    find(:xpath,  "//a[contains(@rel, 'messages-search')]").click

    form = find("form.messages-search")
    form["method"].must_match(/get/i)

    assert form.has_selector?(:xpath, "input[@type='text' and @name='search']")
  end
end