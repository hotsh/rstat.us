require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "profile" do
  include AcceptanceHelper

  it "redirects to the username's profile with the right case" do
    u = Fabricate(:user)
    visit "/users/#{u.username.upcase}"
    current_url.must_match(/\/users\/#{u.username}$/)
  end

  it "allows viewing of profiles when username contains a dot" do
    u = Fabricate(:user, :username => "foo.bar")
    visit "/users/#{u.username}"

    page.within('div.nickname') do
      assert_match /@foo\.bar/, text
    end
  end

  it "has the user's updates on the page in reverse chronological order" do
    heisenbug_log do
      u = Fabricate(:user)
      update1 = Fabricate(:update,
                        :text       => "This is a message posted yesterday",
                        :author     => u.author,
                        :created_at => 1.day.ago)
      update2 = Fabricate(:update,
                        :text       => "This is a message posted last week",
                        :author     => u.author,
                        :created_at => 1.week.ago)
      u.feed.updates << update1
      u.feed.updates << update2

      visit "/users/#{u.username}"
      if page.body.match /#{update1.text}.*#{update2.text}/m
        assert_match /#{update1.text}.*#{update2.text}/m, page.body
      else
        raise Heisenbug
      end
    end
  end

  it "responds with HTML by default if Accept header is */*" do
    u = Fabricate(:user)

    header "Accept", "*/*"
    get "/users/#{u.username}"

    html = Nokogiri::HTML::Document.parse(last_response.body)
    user_text = html.css("span.user-text")

    user_text.first.text.must_match(u.username)
  end

  it "404s if the user doesnt exist" do
    visit "/users/nonexistent"
    assert_match "The page you were looking for doesn't exist.", page.body
  end
end
