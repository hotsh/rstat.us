require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "email change" do
  include AcceptanceHelper

  describe "edit profile" do
    it "update email address" do

      Notifier.expects(:send_confirm_email_notification)

      # Log in to system
      u = Factory(:user, :email => "some@email.com")
      u.password = "password"
      u.save
      pass_hash = u.hashed_password
      log_in_email(u)

      visit "/users/#{u.username}/edit"
      fill_in 'email', :with => 'team@jackhq.com'
      VCR.use_cassette('update_email') do
        click_button 'Save'
      end

      # Need to figure out the best way to do this, expects is swallowing up token generation...
      # refute u.perishable_token.nil?
      assert_match "A link to confirm your updated email address has been sent to team@jackhq.com", page.body

    end

  end

  describe "token" do
    it "has a confirm email link with a token" do
      u = Factory(:user, :email => "someone@somewhere.com")
      token = u.set_password_reset_token
      visit "/confirm_email/#{token}"

      assert_match "Email successfully confirmed.", page.body
      assert_match "/", page.current_url
    end

    it "rejects an invalid token" do
      visit "/confirm_email/abcd"

      assert_match "Can't find User Account for this link.", page.body
      assert_match "/", page.current_url

    end
  end



end
