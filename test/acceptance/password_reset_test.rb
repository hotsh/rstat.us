require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "password reset" do
  include AcceptanceHelper

  describe "token" do
    it "has a reset password link with a token" do
      u = Fabricate(:user, :email => "someone@somewhere.com")
      token = u.create_token
      visit "/reset_password/#{token}"

      assert_match "Set Password", page.body
      assert_match "/reset_password/#{token}", page.current_url
    end

    it "rejects an invalid token" do
      visit "/reset_password/abcd"

      assert_match "Your link is no longer valid, please request a new one.", page.body
      assert_match "/forgot_password", page.current_url
    end

    it "rejects an expired token" do
      u = Fabricate(:user, :email => "someone@somewhere.com")
      token = u.create_token
      u.perishable_token_set = 5.days.ago
      u.save

      visit "/reset_password/#{token}"

      assert_match "Your link is no longer valid, please request a new one.", page.body
      assert_match "/forgot_password", page.current_url
    end

    it "requires a new password" do
      u = Fabricate(:user, :email => "someone@somewhere.com")
      token = u.create_token
      visit "/reset_password/#{token}"

      fill_in "password", :with => ""
      click_button "Reset"

      assert_match "Password must be present", page.body
      assert_match "/reset_password/#{token}", page.current_url
    end

    it "requires the password and confirmation to match" do
      u = Fabricate(:user, :email => "someone@somewhere.com")
      token = u.create_token
      visit "/reset_password/#{token}"

      fill_in "password", :with => "password"
      fill_in "password_confirm", :with => "passrd"
      click_button "Reset"

      assert_match "Passwords do not match", page.body
      assert_match "/reset_password/#{token}", page.current_url
    end

    it "resets the password" do
      u = Fabricate(:user, :email => "someone@somewhere.com")
      token = u.create_token
      visit "/reset_password/#{token}"

      fill_in "password", :with => "password"
      fill_in "password_confirm", :with => "password"
      click_button "Reset"

      assert_match "Password successfully set", page.body
      assert_match "/", page.current_url
    end
  end
end
