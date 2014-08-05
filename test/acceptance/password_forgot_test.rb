require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "forgotten password" do
  include AcceptanceHelper

  it "can't find an account that doesn't exist" do
    visit "/forgot_password"
    fill_in "email", :with => "someone@somewhere.com"
    click_button "Send"

    within flash do
      assert has_content? "Your account could not be found, please check your email and try again."
    end
  end

  it "sets the reset password token" do
    u = Fabricate(:user, :email => "someone@somewhere.com")
    Notifier.expects(:send_forgot_password_notification)
    assert_nil u.perishable_token

    visit "/forgot_password"
    fill_in "email", :with => "someone@somewhere.com"
    click_button "Send"

    u = User.first(:email => "someone@somewhere.com")

    refute u.perishable_token.nil?
    within "div#content p" do
      assert has_content? "A link to reset your password has been sent to someone@somewhere.com."
    end
  end

  it "says try again if you don't enter anything in the email field" do
    visit "/forgot_password"
    click_button "Send"

    within flash do
      assert has_content? "You didn't enter a correct email address. Please check your email and try again."
    end
  end

  it "says try again if you enter something that isn't an email address" do
    visit "/forgot_password"
    fill_in "email", :with => "i like to fill in forms"
    click_button "Send"

    within flash do
      assert has_content? "You didn't enter a correct email address. Please check your email and try again."
    end
  end
end
