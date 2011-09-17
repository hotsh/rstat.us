# encoding: UTF-8
require_relative '../test_helper'

describe Notifier do
  include TestHelper

  before do
    Pony.deliveries.clear
  end

  describe "Notifier#send_forgot_password_notification" do
    it "should send an email" do
      Notifier.send_forgot_password_notification(
        "someone@somewhere.com",
        "some_made_up_token"
      )
      assert_equal 1, Pony.deliveries.count
    end
  end

  describe "Notifier#send_confirm_email_notification" do
    it "should send an email" do
      Notifier.send_confirm_email_notification(
        "someone_else@somewhere_else.com",
        "some_other_made_up_token"
      )
      assert_equal 1, Pony.deliveries.count
    end
  end
end
