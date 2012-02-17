require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "email change" do
  include AcceptanceHelper

  describe "edit profile" do
    it "updates the email address" do

      Notifier.expects(:send_confirm_email_notification)

      # Log in to system
      u = Fabricate(:user, :email => "some@email.com")
      u.password = "password"
      u.save
      pass_hash = u.hashed_password
      log_in_username(u)

      visit "/users/#{u.username}/edit"
      fill_in 'email', :with => 'team@jackhq.com'
      VCR.use_cassette('update_email') do
        click_button 'Save'
      end

      # Need to figure out the best way to do this, expects is swallowing up token generation...
      # refute u.perishable_token.nil?
      within 'div.flash' do
        assert has_content? "A link to confirm your updated email address has been sent to team@jackhq.com"
      end
    end

  end

  describe "token" do
    it "has a confirm email link with a token" do
      u = Fabricate(:user, :email => "someone@somewhere.com")
      token = u.create_token
      visit "/confirm_email/#{token}"

      within 'div.flash' do
        assert has_content? "Email successfully confirmed."
      end

      assert_match "/", page.current_url

      u.reload
      assert u.email_confirmed
    end

    it "rejects an invalid token" do
      visit "/confirm_email/abcd"

      within 'div.flash' do
        assert has_content? "Can't find User Account for this link."
      end

      assert_match "/", page.current_url

    end

    it "rejects an expired token" do
      u = Fabricate(:user, :email => "someone@somewhere.com")
      token = u.create_token
      refute_nil u.perishable_token
      u.perishable_token_set = 5.days.ago
      u.save
      u.reload

      visit "/confirm_email/#{token}"

      within 'div.flash' do
        assert has_content? "Your link is no longer valid, please request a new one."
      end

      assert_match "/", page.current_url

    end
  end



end
