require_relative '../test_helper'

describe PasswordService do
  include TestHelper

  let(:user)    { Fabricate(:user) }

  describe "#invalid?" do
    describe "when password_missing?" do
      describe "when password is not present" do
        let(:options) { { password: "" } }
        let(:password_service) { PasswordService.new(user, options) }

        it "should be invalid?" do
          assert_equal true, password_service.invalid?
        end
      end

      describe "when password is present" do
        let(:options) { { password: "password" } }
        let(:password_service) { PasswordService.new(user, options) }

        it "should be valid" do
          password_service.stubs(:password_mismatch?).returns false
          password_service.stubs(:email_missing?).returns false
          assert_equal false, password_service.invalid?
        end
      end
    end

    describe "when password_mismatch?" do
      describe "when password and confirm pasword don't match" do
        let(:options) { { password: "password", password_confirm: "somepassword" } }
        let(:password_service) { PasswordService.new(user, options) }

        it "should not be valid" do
          assert_equal true, password_service.invalid?
        end
      end

      describe "when password and confirm pasword match" do
        let(:options) { { password: "password", password_confirm: "password" } }
        let(:password_service) { PasswordService.new(user, options) }

        it "should be valid" do
          password_service.stubs(:password_missing?).returns false
          password_service.stubs(:email_missing?).returns false
          assert_equal false, password_service.invalid?
        end
      end
    end

    describe "when email_missing?" do
      describe "when user email not present" do
        let(:user)    { Fabricate(:user, email: nil) }

        describe "and email not present in params" do
          let(:password_service) { PasswordService.new(user) }

          it "should return true" do
            assert_equal true, password_service.invalid?
          end
        end

        describe "and email is present in params" do
          let(:password_service) { PasswordService.new(user, { email: "some@email.com"}) }

          it "should return false" do
            password_service.stubs(:password_missing?).returns false
            password_service.stubs(:password_mismatch?).returns false

            assert_equal false, password_service.invalid?
          end

          it "should set the params email as the use email" do
            password_service.stubs(:password_missing?).returns false
            password_service.stubs(:password_mismatch?).returns false

            assert_equal false, password_service.invalid?
          end
        end
      end

      describe "when user email is present" do
        let(:user)    { Fabricate(:user, email: "some@example.com") }
        let(:password_service) { PasswordService.new(user) }

        it "should NOT say email is missing" do
          password_service.stubs(:password_missing?).returns false
          password_service.stubs(:password_mismatch?).returns false

          assert_equal false, password_service.invalid?
        end
      end
    end
  end

  describe "#reset_password" do
    let(:user)    { Fabricate(:user, email: "some@example.com") }
    let(:password_service) { PasswordService.new(user, password: "password") }

    it "should reset the password successfully" do
      assert_equal true, password_service.reset_password
    end

  end

end
