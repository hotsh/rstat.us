require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "ALPS li.message descendants" do
  include AcceptanceHelper

  before do
    @a_user = Fabricate(:user)
    @an_update = Fabricate(:update, :author     => @a_user.author,
                                    :created_at => Time.parse("Jan 1, 2012 09:34:16 UTC"))
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
    within "li.message span.date-time" do
      assert has_content?("2012-01-01T09:34:16")
    end
  end
end
