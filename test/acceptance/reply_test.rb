require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "replies" do
  include AcceptanceHelper

  it "shows replies" do
    u = Fabricate(:user)
    a = Fabricate(:authorization, :user => u)

    u2 = Fabricate(:user)
    u2.feed.updates << Fabricate(:update, :text => "@#{u.username} Hey man.")

    log_in(u, a.uid)

    visit "/replies"

    assert_match "@#{u.username}", page.body
  end

  it "shows replies with css class mention" do
    u = Fabricate(:user)
    a = Fabricate(:authorization, :user => u)

    u2 = Fabricate(:user)
    a2 = Fabricate(:authorization, :user => u2)
    u2.feed.updates << Fabricate(:update, :text => "@#{u.username} Hey man.")
    u.feed.updates << Fabricate(:update, :text => "some text @someone, @#{u2.username} Hey man.")
    log_in(u, a.uid)
    visit "/updates"

    assert has_selector?("#updates .mention")

    log_in(u2, a2.uid)
    visit "/updates"
    assert has_selector?("#updates .mention")
  end
end
