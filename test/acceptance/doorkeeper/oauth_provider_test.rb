require_relative '../acceptance_helper'

describe "OAuth Provider" do
  include AcceptanceHelper

  describe "authenticating" do
    before do
      @app = Fabricate(:doorkeeper_application)
      @authorize_url = "/oauth/authorize?" + {
        :response_type => "code",
        :client_id     => @app.uid,
        :redirect_uri  => @app.redirect_uri
      }.to_query
    end

    describe "logged out" do
      it "redirects to the login page" do
        visit "/oauth/authorize"
        page.current_url.must_match(/\/login/)
      end

      it "returns to the app after logging in w/username and authorizing" do
        visit @authorize_url + "&return_to=#{@app.redirect_uri}"
        user = Fabricate(:user)
        User.stubs(:authenticate).returns(user)

        within("form") do
          fill_in "username", :with => user.username
          fill_in "password", :with => "anything"
        end
        click_button "Log in"

        click_button "Authorize"

        page.current_url.must_match(@app.redirect_uri)
      end

      it "doesnt show authorized applications" do
        visit "/oauth/authorized_applications"
        page.current_url.must_match(/\/login/)
      end
    end

    describe "logged in" do
      before do
        log_in_as_some_user
      end

      describe "without an application" do
        it "fails with an error" do
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

        it "asks for the default scope" do
          visit @authorize_url
          within "#content" do
            assert has_content?("Read your public data")
            assert has_no_content?("Post on your behalf and update your information")
          end
        end

        it "asks for the specified scopes" do
          visit @authorize_url + "&scope=read+write"
          within "#content" do
            assert has_content?("Read your public data")
            assert has_content?("Post on your behalf and update your information")
          end
        end

        it "lists the apps you've authorized, their scopes, and has Revoke buttons" do
          visit @authorize_url + "&scope=read+write"
          click_button "Authorize"

          code = CGI::parse(URI.parse(current_url).query)["code"].first

          # have to *use* the authorization before it shows up in the list

          post "/oauth/token", {"grant_type"    => "authorization_code",
                                "code"          => code,
                                "client_id"     => @app.uid,
                                "client_secret" => @app.secret,
                                "redirect_uri"  => @app.redirect_uri}

          visit "/oauth/authorized_applications"

          save_and_open_page

          assert has_content? @app.name
          assert has_link? "Revoke"
        end
      end
    end
  end
end
