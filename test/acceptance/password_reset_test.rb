require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "password reset" do
  include AcceptanceHelper

  describe "token" do
    it "has a reset password link with a token" do
      u = Factory(:user, :email => "someone@somewhere.com")
      token = u.set_password_reset_token
      visit "/reset_password/#{token}"

      assert_match "Password Reset", page.body
      assert_match "/reset_password/#{token}", page.current_url
    end

    it "rejects an invalid token" do
      visit "/reset_password/abcd"

      assert_match "Your link is no longer valid, please request a new one.", page.body
      assert_match "/forgot_password", page.current_url
    end

    it "rejects an expired token" do
      u = Factory(:user, :email => "someone@somewhere.com")
      token = u.set_password_reset_token
      u.password_reset_sent = 5.days.ago
      u.save

      visit "/reset_password/#{token}"

      assert_match "Your link is no longer valid, please request a new one.", page.body
      assert_match "/forgot_password", page.current_url
    end

    it "requires a new password" do
      u = Factory(:user, :email => "someone@somewhere.com")
      token = u.set_password_reset_token
      visit "/reset_password/#{token}"

      fill_in "password", :with => ""
      click_button "Reset"

      assert_match "Password must be present", page.body
      assert_match "/reset_password/#{token}", page.current_url
    end

    it "requires the password and confirmation to match" do
      u = Factory(:user, :email => "someone@somewhere.com")
      token = u.set_password_reset_token
      visit "/reset_password/#{token}"

      fill_in "password", :with => "password"
      fill_in "password_confirm", :with => "passrd"
      click_button "Reset"

      assert_match "Passwords do not match", page.body
      assert_match "/reset_password/#{token}", page.current_url
    end

    it "resets the password" do
      u = Factory(:user, :email => "someone@somewhere.com")
      token = u.set_password_reset_token
      visit "/reset_password/#{token}"

      fill_in "password", :with => "password"
      fill_in "password_confirm", :with => "password"
      click_button "Reset"

      assert_match "Password successfully set", page.body
      assert_match "/", page.current_url
    end
  end

  describe "logged in" do
    it "changes the password" do
      u = Factory(:user, :email => "some@email.com")
      u.password = "password"
      u.save
      pass_hash = u.hashed_password
      log_in_email(u)

      visit "/users/password_reset"
      assert_match "Password Reset", page.body

      fill_in "password", :with => "password"
      fill_in "password_confirm", :with => "password"
      click_button "Reset"

      u = User.first(:email => "some@email.com")
      assert u.hashed_password != pass_hash
      assert_match "Password successfully set", page.body
      assert_match "/", page.current_url
    end

    it "prompts for email if not present" do
      user = Factory(:user, :email => nil)
      a = Factory(:authorization, :user => user)
      log_in(user, a.uid)

      visit "/users/password_reset"

      assert_match "Set Password", page.body

      fill_in "email", :with => "some@email.com"
      fill_in "password", :with => "password"
      fill_in "password_confirm", :with => "password"
      click_button "Reset"

      u = User.first(:id => user.id)
      refute u.hashed_password.nil?
      refute u.email.nil?
      assert_match "Password successfully set", page.body
      assert_match "/", page.current_url
    end

    it "requires an email if not present" do
      u = Factory(:user, :email => nil)
      a = Factory(:authorization, :user => u)
      log_in(u, a.uid)

      visit "/users/password_reset"

      assert_match "Set Password", page.body

      fill_in "password", :with => "password"
      fill_in "password_confirm", :with => "password"
      click_button "Reset"

      assert_match "Email must be provided", page.body
      assert_match "/users/password_reset", page.current_url
    end

    it "does not prompt for email if the user has one specified" do
      u = Factory(:user, :email => "something@something.com")
      a = Factory(:authorization, :user => u)
      log_in(u, a.uid)

      visit "/users/password_reset"

      assert_equal page.has_selector?("input[name=email]"), false
    end

    it "requires password and confirmation to match" do
      u = Factory(:user, :email => "some@email.com")
      log_in_email(u)

      visit "/users/password_reset"

      fill_in "password", :with => "password"
      fill_in "password_confirm", :with => "pasord"
      click_button "Reset"

      assert_match "Passwords do not match", page.body
      assert_match "/users/password_reset", page.current_url
    end

    it "requires a new password" do
      u = Factory(:user, :email => "some@email.com")
      log_in_email(u)

      visit "/users/password_reset"

      click_button "Reset"

      assert_match "Password must be present", page.body
      assert_match "/users/password_reset", page.current_url
    end

    it "has a link to set password if none has ever been set" do
      u = Factory(:user, :email => "some@email.com")
      log_in_email(u)

      visit "/users/#{u.username}/edit"

      assert_match "Set Password", page.body
    end

    it "has a link to REset password if there is a previous password" do
      u = Factory(:user, :email => "some@email.com", :hashed_password => "blerg")
      log_in_email(u)

      visit "/users/#{u.username}/edit"

      assert_match "Reset Password", page.body
    end
  end

  it "goes to forgot password when you try to reset when not logged in" do
    visit "/users/password_reset"

    assert_match "/forgot_password", page.current_url
  end
end
