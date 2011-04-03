require 'rack/test'
require 'vcr'

require_relative '../../rstatus'
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
  
  def log_in_email(user)
    User.stubs(:authenticate).returns(user)
    visit "/login"
    within("form") do
      fill_in "username", :with => user.username
      fill_in "password", :with => "anything"
    end
    click_button "Log in"
  end
  
  Capybara.app = Rstatus
end
