require_relative 'acceptance_helper'

describe "edit profile" do
  include AcceptanceHelper

  describe "logged in" do
    before do
      Pony.deliveries.clear
      log_in_as_some_user
    end

    it "has a link to edit your own profile" do
      visit "/users/#{@u.username}"

      assert has_link? "Edit"
    end

    attributes_without_confirmation = {"username" => "foobar",
                                       "name"     => "Mark Zuckerberg",
                                       "website"  => "http://test.com",
                                       "bio"      => "To be or not to be"}

    attributes_without_confirmation.each do |key, value|
      it "updates your #{key}" do
        visit "/users/#{@u.username}/edit"
        find("##{key}").set value
        #fill_in key, :with => value

        VCR.use_cassette("update_profile_#{key}") do
          click_button "Save"
        end

        within profile(key) do
          assert has_content?(value), "Cannot find #{key} with text #{value}"
        end
      end
    end

    it "does not update your username if the chosen username already exists" do
      visit "/users/#{@u.username}/edit"

      u = Fabricate(:user, :username => "foobar")

      fill_in "username", :with => "foobar"

      click_button "Save"

      within flash do
        assert has_content?("Username has already been taken")
      end
    end

    it "redirects to your new name when you change your username" do
      visit "/users/#{@u.username}/edit"

      fill_in "username", :with => "foobar"

      VCR.use_cassette("update_profile_username") do
        click_button "Save"
      end

      assert_match /\/users\/foobar$/, page.current_url
    end

    it "does not allow you to change your username to something invalid" do
      visit "/users/#{@u.username}/edit"

      fill_in "username", :with => "#foobar."

      click_button "Save"

      within flash do
        assert has_content?("Username contains restricted characters")
      end
    end

    it "updates your password successfully" do
      visit "/users/#{@u.username}/edit"

      fill_in "password", :with => "new_password"
      fill_in "password_confirm", :with => "new_password"

      VCR.use_cassette("update_profile_password") do
        click_button "Save"
      end

      within profile "name" do
        assert has_content?(@u.author.name), "Password update failed"
      end
    end

    it "does not update your password if the confirmation doesn't match" do
      visit "/users/#{@u.username}/edit"
      fill_in "password", :with => "new_password"
      fill_in "password_confirm", :with => "bunk"

      click_button "Save"

      within flash do
        assert has_content?("Sorry, 1 error we need you to fix:")
        assert has_content?("Password doesn't match confirmation.")
      end

      assert has_field?("password")
    end

    it "shows multiple error messages if there are multiple problems" do
      visit "/users/#{@u.username}/edit"

      fill_in "username", :with => "something too_long&with invalid#chars."

      fill_in "password", :with => "new_password"
      fill_in "password_confirm", :with => "bunk"

      click_button "Save"

      within flash do
        assert has_content?("Sorry, 3 errors we need you to fix:")
        assert has_content?("Password doesn't match confirmation.")
        assert has_content?("Username contains restricted characters.")
        assert has_content?("Username must be 17 characters or fewer.")
      end
    end

    it "verifies your email if you change it" do
      visit "/users/#{@u.username}/edit"
      email = "new_email@new_email.com"
      fill_in "email", :with => email

      VCR.use_cassette('update_profile_email') do
        click_button "Save"
      end

      within profile "name" do
        assert has_content? @u.author.name
      end

      assert_equal 1, Pony.deliveries.size
    end

    it "does not verify your email if you havent specified one" do
      user_without_email = Fabricate(:user, :email => nil, :username => "no_email")
      a = Fabricate(:authorization, :user => user_without_email)

      log_in(user_without_email, a.uid)
      visit "/users/#{user_without_email.username}/edit"
      name = "Mark Zuckerberg"
      find('#name').set name
      #fill_in '#name', :with => name

      VCR.use_cassette('update_profile_no_email') do
        click_button "Save"
      end

      within profile "name" do
        assert has_content? name
      end

      assert Pony.deliveries.empty?
    end

    it "does not verify your email if you havent changed it" do
      visit "/users/#{@u.username}/edit"
      name = "Steve Jobs"
      find('#name').set name
      #fill_in "#name", :with => name

      VCR.use_cassette('update_profile_no_email') do
        click_button "Save"
      end

      within profile "name" do
        assert has_content? name
      end

      assert Pony.deliveries.empty?
    end

    describe "avatar" do
      describe "with image_url" do
        before do
          @u.author.image_url = "https://example.com/avatar.png"
          @u.author.save
          visit "/users/#{@u.username}/edit"
        end

        it "shows you the avatar whose URL came from twitter" do
          within ".avatar .avatar-management" do
            assert has_selector?(:xpath, "//img[@src='https://example.com/avatar.png']")
            assert has_content?("Saved from a linked account")
          end
        end

        it "lets you remove that avatar from your account" do
          within ".avatar .avatar-management" do
            click_button "Remove Avatar"
          end

          within ".avatar .avatar-management" do
            assert has_no_selector?(:xpath, "//img[@src='https://example.com/avatar.png']")
          end
        end
      end

      describe "with email" do
        before do
          @u.author.email = "test@example.com"
          @u.author.save
          visit "/users/#{@u.username}/edit"
        end

        it "shows you the gravatar with your email address" do
          within ".avatar .avatar-management" do
            assert has_selector?(:xpath, "//img[@src='#{@u.author.gravatar_url}']")
            assert has_content?("Gravatar using test@example.com")
            assert has_link?("Go to Gravatar to change")
          end
        end
      end

      describe "with neither image_url nor email" do
        before do
          @u.author.email = ""
          @u.author.save
          visit "/users/#{@u.username}/edit"
        end

        it "says you should add an email address and use gravatar" do
          within ".avatar .avatar-management" do
            assert has_selector?(:xpath, "//img[contains(@src, '#{RstatUs::DEFAULT_AVATAR}')]")
            assert has_content?("Add an email to your profile above")
          end
        end
      end
    end

    it "does let you update your profile even if you use a different case in the url" do
      u = Fabricate(:user, :username => "LADY_GAGA")
      a = Fabricate(:authorization, :user => u)
      log_in(u, a.uid)

      visit "/users/lady_gaga/edit"
      bio_text = "To be or not to be"
      fill_in "bio", :with => bio_text

      VCR.use_cassette('update_profile_different_case') do
        click_button "Save"
      end

      within profile "bio" do
        assert has_content? bio_text
      end
    end

    it "doesn't let you update someone else's profile" do
      u = Fabricate(:user)
      visit "/users/#{u.username}/edit"
      assert_match /\/users\/#{u.username}$/, page.current_url
    end
  end

  describe "logged out" do
    it "doesn't let a logged out user update someone's profile" do
      u = Fabricate(:user)
      visit "/users/#{u.username}/edit"
      page.current_url.wont_match(/\/users\/#{u.username}\/edit/)
    end
  end
end
