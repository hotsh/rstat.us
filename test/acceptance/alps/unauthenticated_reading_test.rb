require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "Unauthenticated reading" do
  include AcceptanceHelper

  describe "ALPS starting URI, rstat.us homepage (logged out /)" do
    it "can transition to all updates" do
      visit "/"
      assert has_selector?(:xpath, "//a[contains(@rel, 'messages-all')]")
    end
  end

  describe "ALPS all, rstat.us world (/updates)" do
    it "has an individual status in an li with class message" do
      @u2 = Fabricate(:user)
      @update = Fabricate(:update)
      @u2.feed.updates << @update

      visit "/updates"

      within "div#messages ul.all li.message" do
        assert has_content? @update.text
      end
    end

    it "can transition to the application root" do
      visit "/updates"
      assert has_selector?(:xpath, "//a[contains(@rel, 'index')]")
    end
  end

  describe "ALPS single, rstat.us update show" do
    before do
      @update = Fabricate(:update)
      visit "/updates/#{@update.id}"
    end

    it "shows the status in a ul with class single" do
      within "div#messages ul.single li.message" do
        assert has_content? @update.text
      end
    end

    it "can transition to all updates" do
      assert has_selector?(:xpath, "//a[contains(@rel, 'messages-all')]")
    end

    it "can transition to the application root" do
      assert has_selector?(:xpath, "//a[contains(@rel, 'index')]")
    end
  end

  describe "pagination" do
    it "does not paginate when there are too few" do
      5.times do
        Fabricate(:update)
      end

      visit "/updates"

      assert has_no_selector?(:xpath, "//a[contains(@rel, 'previous')]")
      assert has_no_selector?(:xpath, "//a[contains(@rel, 'next')]")
    end

    it "paginates forward only if on the first page" do
      30.times do
        Fabricate(:update)
      end

      visit "/updates"

      assert has_no_selector?(:xpath, "//a[contains(@rel, 'previous')]")
      assert has_selector?(:xpath, "//a[contains(@rel, 'next')]")
    end

    it "paginates backward only if on the last page" do
      30.times do
        Fabricate(:update)
      end

      visit "/updates"
      find(:xpath, "//a[contains(@rel, 'next')]").click

      assert has_selector?(:xpath, "//a[contains(@rel, 'previous')]")
      assert has_no_selector?(:xpath, "//a[contains(@rel, 'next')]")
    end

    it "paginates forward and backward if on a middle page" do
      54.times do
        Fabricate(:update)
      end

      visit "/updates"
      find(:xpath, "//a[contains(@rel, 'next')]").click

      assert has_selector?(:xpath, "//a[contains(@rel, 'previous')]")
      assert has_selector?(:xpath, "//a[contains(@rel, 'next')]")
    end
  end
end