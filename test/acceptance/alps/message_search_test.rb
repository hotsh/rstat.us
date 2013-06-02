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
    find(:xpath,  "(//a[contains(@rel, 'messages-search')])[1]").click

    form = find("form.messages-search")
    form["method"].must_match(/get/i)

    assert form.has_selector?(:xpath, "input[@type='text' and @name='search']")
  end

  it "does a search when using the form as a template" do
    @update_text = "These aren't the droids you're looking for!"
    Fabricate(:update, :text => @update_text)

    visit "/"
    find(:xpath,  "(//a[contains(@rel, 'messages-search')])[1]").click

    form = find("form.messages-search")
    visit "#{form["action"]}?search=droids"

    within ".message-text" do
      assert has_content? @update_text
    end
  end
end