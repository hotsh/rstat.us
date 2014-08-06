# encoding: UTF-8
require_relative '../test_helper'
require "webmock"
include WebMock::API

describe Admin do
  include TestHelper

  describe "can_create_user?" do
    it "must not allow user creation when there are Users and multiuser is false" do
      u = Fabricate(:user)
      refute Admin.new(:multiuser => false).can_create_user?
    end

    it "must allow user creation when there are Users and multiuser is true" do
      u = Fabricate(:user)
      assert Admin.new(:multiuser => true).can_create_user?
    end

    it "must allow user creation when there aren't Users and multiuser is false" do
      assert Admin.new(:multiuser => false).can_create_user?
    end

    it "must allow user creation when there aren't Users and multiuser is true" do
      assert Admin.new(:multiuser => true).can_create_user?
    end
  end
end
