require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "User searching" do
  include AcceptanceHelper

  it "can transition to the user search page from the homepage" do
    visit "/"
    assert has_selector?(:xpath, "//a[contains(@rel, 'users-search')]")
  end

  it "has a form with the right attributes and input" do
    visit "/"
    find(:xpath,  "(//a[contains(@rel, 'users-search')])[1]").click

    form = find("form.users-search")
    form["method"].must_match(/get/i)

    assert form.has_selector?(:xpath, "input[@type='text' and @name='search']")
  end

  it "does a search when using the form as a template" do
    zebra = Fabricate(:user, :username => "zebra")

    visit "/"
    find(:xpath,  "(//a[contains(@rel, 'users-search')])[1]").click 

    form = find("form.users-search")
    visit "#{form["action"]}?search=zebra"

    within "div#users ul.search li.user span.user-text" do
      assert has_content? zebra.username
    end
  end
end