ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'yaml'
require 'database_cleaner'
require 'factory_girl'
require 'mocha'
require_relative 'factories'

require_relative '../rstatus'

module TestHelper
  require 'capybara/dsl'
  include Capybara
  include Rack::Test::Methods
  include Sinatra::UserHelper

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
    return OmniAuth.config.add_mock(provider, {
      :uid => options[:uid] || 12345,
      :user_info => {
        :name => "Joe Public",
        :email => "joe@public.com",
        :nickname => username,
        :urls => { :Website => "http://rstat.us" },
        :description => "A description",
        :image => "/images/something.png"
      },
      :credentials => {:token => "1234", :secret => "4567"}
    })
  end

  def log_in(u, uid = 12345)
    Author.any_instance.stubs(:valid_gravatar?).returns(:false)
    omni_mock(u.username, {:uid => uid})

    visit '/auth/twitter'
  end
  
  def log_in_fb(u, uid = 12345)
    Author.any_instance.stubs(:valid_gravatar?).returns(:false)
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
