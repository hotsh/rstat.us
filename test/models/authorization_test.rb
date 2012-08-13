require_relative '../test_helper'

describe Authorization do
  include TestHelper
  before do
    @u = Fabricate(:user)
  end

  it "can be found from a hash" do
    a = Fabricate(:authorization, :user => @u)

    assert_equal a, Authorization.find_from_hash(auth_response(@u.username, {:uid => a.uid}))
  end

  it "can be created from a hash" do
    auth = auth_response(@u.username)
    a = Authorization.create_from_hash!(auth, "/", @u)

    assert_equal auth["uid"], a.uid
    assert_equal auth["provider"], a.provider
    assert_equal auth["info"]["nickname"], a.nickname
    assert_equal auth['credentials']['token'], a.oauth_token
    assert_equal auth['credentials']['secret'], a.oauth_secret
  end

  it "is not valid without a uid" do
    a = Authorization.new(:uid => nil, :provider => "twitter")
    assert_equal a.save, false
    assert_equal a.errors[:uid], ["can't be blank"]
  end

  it "is not valid without a provider" do
    a = Authorization.new(:uid => 12345, :provider => nil)
    assert_equal a.save, false
    assert_equal a.errors[:provider], ["can't be blank"]
  end
end
