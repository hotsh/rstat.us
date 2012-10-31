require_relative '../acceptance_helper'

describe "Account API endpoints" do
  include AcceptanceHelper

  describe "verify_credentials" do
    describe "with an authenticated user" do
      before do
        @app = Fabricate(:doorkeeper_application)
        @u = Fabricate(:user)
        @token = Fabricate(:doorkeeper_access_token,
          :application    => @app,
          :resource_owner_id => @u.id
        )
      end

      it "returns the authenticated user's info (useful for omniauth)" do
        get "/api/account/verify_credentials.json", {:access_token => @token.token}
        parsed_json = JSON.parse(last_response.body)
        parsed_json["screen_name"].must_equal(@u.username)
      end
    end

    describe "unauthenticated" do
      it "returns 401 unauthorized" do
        get "/api/account/verify_credentials.json"
        last_response.status.must_equal 401
      end
    end
  end
end