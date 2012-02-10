require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "replies" do
  include AcceptanceHelper

  it "shows replies" do
    log_in_as_some_user

    u2 = Fabricate(:user)
    u2.feed.updates << Fabricate(:update, :text => "@#{@u.username} Hey man.")

    visit "/replies"

    assert_match "@#{@u.username}", page.body
  end

  it "shows replies with css class mention" do
    log_in_as_some_user

    u2 = Fabricate(:user)
    a2 = Fabricate(:authorization, :user => u2)

    u2.feed.updates << Fabricate(:update, :text => "@#{@u.username} Hey man.")
    @u.feed.updates << Fabricate(:update, :text => "some text @someone, @#{u2.username} Hey man.")
    visit "/updates"

    assert has_selector?("#updates .mention")

    log_in(u2, a2.uid)
    visit "/updates"
    assert has_selector?("#updates .mention")
  end
end
