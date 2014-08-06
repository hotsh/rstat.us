require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "admin" do
  include AcceptanceHelper

  it "creates the first user account as an admin" do
    u = User.first(:username => "new_user")
    assert u.nil?

    visit '/login'

    fill_in 'username', :with => 'new_user'
    fill_in 'password', :with => 'mypassword'
    click_button 'Log in'

    u = User.first(:username => "new_user")
    refute u.nil?
    assert u.admin
  end

  it "redirects first user to admin page after signup" do
    u = User.first(:username => "new_user")
    assert u.nil?

    visit '/login'

    fill_in 'username', :with => 'new_user'
    fill_in 'password', :with => 'mypassword'
    click_button 'Log in'

    assert_match /\/admin$/, page.current_url
  end

  it "admin page is accessible by admin users" do
    existing_user = Fabricate(:user, :admin => true, :username => "taken")
    log_in_username(existing_user)

    visit '/admin'

    assert_match /\/admin$/, page.current_url
  end

  it "admin page is not accessible by non-admin users" do
    existing_user = Fabricate(:user, :admin => false, :username => "taken")
    log_in("taken")

    visit '/admin'

    refute_match /\/admin$/, page.current_url
  end

  it "admin page allows you to turn on multiuser setting" do
    existing_user = Fabricate(:user, :admin => true, :username => "taken")
    log_in_username(existing_user)

    visit '/admin'

    check 'multiuser'
    click_button 'submit'

    assert Admin.first.multiuser == true
  end

  it "admin page allows you to turn off multiuser setting" do
    existing_user = Fabricate(:user, :admin => true, :username => "taken")
    log_in_username(existing_user)

    visit '/admin'

    uncheck :multiuser
    click_button :submit

    assert Admin.first.multiuser == false
  end

  it "admin page allows you to see the current multiuser setting" do
    Admin.create(:multiuser => true)

    existing_user = Fabricate(:user, :admin => true, :username => "taken")
    log_in_username(existing_user)

    visit '/admin'

    assert find('#multiuser').checked? == "checked"
  end
end
