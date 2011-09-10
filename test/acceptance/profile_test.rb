require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "profile" do
  include AcceptanceHelper

  it "redirects to the username's profile with the right case" do
    u = Factory(:user)
    url = "http://www.example.com/users/#{u.username}"
    visit "/users/#{u.username.upcase}"
    assert_equal url, page.current_url
  end

  it "has the user's updates on the page in reverse chronological order" do
    u = Factory(:user)
    update1 = Factory(:update,
                      :text       => "This is a message posted yesterday",
                      :author     => u.author,
                      :created_at => 1.day.ago)
    update2 = Factory(:update,
                      :text       => "This is a message posted last week",
                      :author     => u.author,
                      :created_at => 1.week.ago)
    u.feed.updates << update1
    u.feed.updates << update2

    visit "/users/#{u.username}"
    assert_match /#{update1.text}.*#{update2.text}/m, page.body
  end

  it "404s if the user doesnt exist" do
    visit "/users/nonexistent"
    assert_match "The page you were looking for doesn't exist.", page.body
  end

  it "has a link to edit your own profile" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    visit "/users/#{u.username}"

    assert has_link? "Edit"
  end

  it "updates your profile" do
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    visit "/users/#{u.username}/edit"
    bio_text = "To be or not to be"
    fill_in "bio", :with => bio_text
    click_button "Save"

    assert_match page.body, /#{bio_text}/
  end

  it "doesn't let you update someone else's profile" do
    u = Factory(:user)
    visit "/users/#{u.username}/edit"
    assert_match /\/users\/#{u.username}$/, page.current_url
  end

  it "does let you update your profile even if you use a different case in the url" do
    u = Factory(:user, :username => "LADY_GAGA")
    a = Factory(:authorization, :user => u)
    log_in(u, a.uid)
    visit "/users/lady_gaga/edit"
    bio_text = "To be or not to be"
    fill_in "bio", :with => bio_text
    click_button "Save"

    assert_match page.body, /#{bio_text}/
  end
end
