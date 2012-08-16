require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "OAuth Provider" do
  include AcceptanceHelper

  before do
    @app = Fabricate(:doorkeeper_application)
    @authorize_url = "/oauth/authorize?" + {
      :response_type => "code",
      :client_id     => @app.uid,
      :redirect_uri  => @app.redirect_uri
    }.to_query
  end

  describe "logged out" do
    before do
      visit "/logout"
    end

    it "should redirect to the login page" do
      visit "/oauth/authorize"
      page.current_url.must_match(/\/login$/)
    end

    it "should return to the application after logging in" do
      visit @authorize_url + "&return_to=#{@app.redirect_uri}"
      log_in_as_some_user
      page.current_url.must_match(@app.redirect_uri)
    end
  end

  describe "logged in" do
    before do
      log_in_as_some_user
    end

    describe "without an application" do
      it "should fail with an error" do
        visit "/oauth/authorize"
        assert has_content? "Client authentication failed due to unknown client, no client authentication included, or unsupported authentication method."
      end
    end

    describe "with an application" do
      it "lets you authorize the app" do
        visit @authorize_url
        click_button "Authorize"
        page.current_url.must_match(@app.redirect_uri)
        page.current_url.must_match(/code=/)
        page.current_url.wont_match(/access_denied/)
      end

      it "lets you deny the app" do
        visit @authorize_url
        click_button "Deny"
        page.current_url.must_match(@app.redirect_uri)
        page.current_url.must_match(/error=access_denied/)
      end
    end
  end
end
