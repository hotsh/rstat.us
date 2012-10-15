require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "export updates" do
  include AcceptanceHelper

  describe "logged in" do
    before do
      log_in_as_some_user
      update = Fabricate(:update, :author => @u.author)
    end

    it "has a link to export all updates" do
      visit "/users/#{@u.username}"
      assert has_link? "Export all updates"
    end

    it "exports all updates in json format" do
      visit "/users/#{@u.username}"
      click_link "Export all updates"
      assert_equal "application/json", page.response_headers['Content-Type']
      assert_match /#{@u.username}-updates.json/, page.response_headers['Content-Disposition']
    end

  end

  describe "unauthorized" do
    before { visit "/export" }
    it "should redirect to root page" do
      assert page.has_selector? 'div#signup'
    end
  end

end
