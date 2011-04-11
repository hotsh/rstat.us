require 'rack/test'
require 'vcr'

require_relative '../test_helper'

VCR.config do |c|
  c.cassette_library_dir = 'test/data/vcr_cassettes'
  c.stub_with :webmock
end

module AcceptanceHelper
  require 'capybara/dsl'
  include Capybara
  include Rack::Test::Methods
  include Sinatra::UserHelper
  include TestHelper

  OmniAuth.config.test_mode = true

  def app() Rstatus end

  def setup
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  def omni_mock(username, options={})
    provider = (options[:provider] || :twitter).to_sym
    return OmniAuth.config.add_mock(provider, auth_response(username, options))
  end

  def log_in(u, uid = 12345)
    omni_mock(u.username, {:uid => uid})

    visit '/auth/twitter'
  end

  def log_in_fb(u, uid = 12345)
    omni_mock(u.username, {:uid => uid, :provider => :facebook})

    visit '/auth/facebook'
  end

  def log_in_email(user, remember_me = false)
    User.stubs(:authenticate).returns(user)
    visit "/login"
    within("form") do
      fill_in "username", :with => user.username
      fill_in "password", :with => "anything"
      check "remember_me" if remember_me
    end
    click_button "Log in"
  end

  def cookies
    rack_test_driver = Capybara.current_session.driver
    cookie_jar = rack_test_driver.current_session.instance_variable_get(:@rack_mock_session).cookie_jar
  end

  def session_expires
    cookies.send(:hash_for)['rack.session'].expires
  end

  Capybara.app = Rstatus
end
