require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "ALPS li.user descendants" do
  include AcceptanceHelper

  before do
    @user = Fabricate(:user, :username => "alps")
    visit "/users?search=#{@user.username}"
  end

  it "has the user nickname in span.user-text" do
    within "li.user span.user-text" do
      assert has_content? @user.username
    end
  end

  it "has a link to the user's profile page in a.rel=user" do
    within "li.user" do
      assert has_selector?(
        :xpath,
        ".//a[contains(@rel, 'user') and @href='#{@user.url}']"
      )
    end
  end

  it "has a link to the user's profile page in a.rel=messages" do
    within "li.user" do
      assert has_selector?(
        :xpath,
        ".//a[contains(@rel, 'messages') and @href='#{@user.url}']"
      )
    end
  end

  it "has the user's bio in span.description" do
    within "li.user span.description" do
      assert has_content? @user.author.bio
    end
  end

  it "has a gravatar in img.user-image" do
    within "li.user" do
      assert has_selector?(
        :xpath,
        "//img[contains(@class, 'user-image') and @src='#{@user.author.avatar_url}']"
      )
    end
  end
end
