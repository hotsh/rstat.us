require_relative '../acceptance_helper'

describe "Creating OAuth Applications" do
  include AcceptanceHelper

  before do
    @oauth_app = Fabricate(:doorkeeper_application)
  end

  describe "not logged in" do
    it "should not allow access to the oauth application management pages" do
      ["/oauth/applications",
       "/oauth/applications/new",
       "/oauth/applications/#{@oauth_app.id}/edit",
       "/oauth/applications/#{@oauth_app.id}"].each do |oauth_url|

        visit oauth_url
        page.current_url.wont_match(oauth_url)
      end

    end
  end

  describe "logged in" do
    before do
      log_in_as_some_user
    end

    it "can create an application" do
      visit "/oauth/applications/new"
      fill_in "application_name", :with => "RStatusDeck"
      fill_in "application_redirect_uri", :with => "http://rstatusdeck.com/oauth/callback"
      click_button "Submit"

      within "#content" do
        assert has_content?("Application: RStatusDeck")
      end
    end

    it "doesn't show you other developers' applications" do
      @oauth_app = Fabricate(:doorkeeper_application)
      @my_oauth_app = Fabricate(:doorkeeper_application,
        :owner => @u,
        :name => "My special app"
      )
      visit "/oauth/applications"

      within "#content" do
        assert has_content?("My special app")
        assert has_no_content?(@oauth_app.name)
      end
    end
  end
end