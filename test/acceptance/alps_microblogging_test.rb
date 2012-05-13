require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

# This file tests our compatibility with the ALPS microblogging profile
# defined at http://amundsen.com/hypermedia/profiles/

describe "ALPS microblogging spec" do
  include AcceptanceHelper

  describe "messages" do
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

    describe "ALPS me, rstat.us user's profile page" do
      it "has a user's updates in a ul with class me" do
        @u2 = Fabricate(:user)
        @update = Fabricate(:update, :author => @u2.author)
        @u2.feed.updates << @update

        visit "/users/#{@u2.username}"

        within "div#messages ul.me li.message" do
          assert has_content? @update.text
        end
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

    describe "ALPS li.message descendants" do
      before do
        @a_user = Fabricate(:user)
        @an_update = Fabricate(:update, :author => @a_user.author)
        @a_user.feed.updates << @an_update

        visit "/updates"
      end

      it "has the user nickname in span.user-text" do
        within "li.message span.user-text" do
          assert has_content? @a_user.username
        end
      end

      it "has a link to the user's profile page in a.rel=user" do
        within "li.message" do
          assert has_selector?(
            :xpath,
            ".//a[contains(@rel, 'user') and @href='#{@a_user.url}']"
          )
        end
      end

      it "has the text of the status in span.message-text" do
        within "li.message span.message-text" do
          assert has_content? @an_update.text
        end
      end

      it "has the permalink to the update in a.rel=message" do
        within "li.message" do
          assert has_selector?(
            :xpath,
            "//a[contains(@rel, 'message') and @href='#{@an_update.url}']"
          )
        end
      end

      it "has a gravatar in img.user-image" do
        within "li.message" do
          assert has_selector?(
            :xpath,
            "//img[contains(@class, 'user-image') and @src='#{@a_user.author.avatar_url}']"
          )
        end
      end

      it "has the update time in span.date-time" do
        # valid per RFC3339
        within "li.message" do
          assert has_selector?("span.date-time")
        end
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
end