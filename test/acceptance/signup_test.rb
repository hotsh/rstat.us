require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "signup" do
  include AcceptanceHelper

  describe "username" do
    it "signs up successfully" do
      u = User.first(:username => "new_user")
      assert u.nil?

      visit '/login'
      fill_in "username", :with => "new_user"
      fill_in "password", :with => "mypassword"
      click_button "Log in"

      u = User.first(:username => "new_user")
      refute u.nil?
      assert User.authenticate("new_user", "mypassword")
    end

    it "prompts for a new username if it contains spaces" do
      visit '/login'
      fill_in "username", :with => "space something"
      fill_in "password", :with => "baseball"
      click_button "Log in"

      assert_match /Sorry, 1 error we need you to fix:/, page.body
      assert_match /contains restricted characters\./, page.body
    end

    it "requires a username" do
      visit '/login'
      fill_in "password", :with => "baseball"
      click_button "Log in"

      assert_match /Sorry, 1 error we need you to fix:/, page.body
      assert_match /Username can't be blank/, page.body
    end

    it "requires a password" do
      visit '/login'
      fill_in "username", :with => "baseball"
      click_button "Log in"

      assert_match /Password can't be empty/, page.body
    end

    it "does not save user to db if there wasn't a password" do
      visit '/login'
      fill_in "username", :with => "baseball"
      click_button "Log in"

      assert_match /Password can't be empty/, page.body

      fill_in "username", :with => "baseball"
      fill_in "password", :with => "baseball"
      click_button "Log in"

      refute_match /The username exists; the password you entered was incorrect\. If you are trying to create a new account, please choose a different username/, page.body
      refute_match /prohibited your account from being created/, page.body
      assert_match /\//, page.current_url
    end

    it "shows an error if the username is too long" do
      visit '/login'

      fill_in "username", :with => "supercalifragilisticexpialidocious"
      fill_in "password", :with => "baseball"

      click_button "Log in"

      assert_match /Sorry, 1 error we need you to fix:/, page.body
      assert_match /Username must be 17 characters or fewer\./, page.body
    end
  end

  describe "twitter" do
    it "prompts for a new username if it clashes" do
      existing_user = Fabricate(:user, :username => "taken")

      log_in("taken")

      assert_match /users\/new/, page.current_url, "not on the new user page."

      fill_in "username", :with => "taken"
      click_button "Finish Signup"

      assert_match /Sorry, 1 error we need you to fix:/, page.body
      assert_match /Username has already been taken/, page.body

      fill_in "username", :with => "nottaken"
      click_button "Finish Signup"

      assert_match /Thanks! You're all signed up with nottaken for your username\./, page.body
      refute_match /prohibited your account from being created/, page.body
      assert_match /\//, page.current_url
    end
  end
end
