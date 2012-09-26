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
  end
end