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

  def omni_mock(username, uid = 12345)
    return OmniAuth.config.add_mock(:twitter, {
      :uid => uid,
      :user_info => {
        :name => "Joe Public",
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
    omni_mock(u.username, uid)

    visit '/auth/twitter'
  end

  def log_in_fb(u, uid = 12345)
    OmniAuth.config.add_mock(:facebook, {
      :uid => uid,
      :user_info => {
        :name => "Jane Public",
        :nickname => u.username,
        :urls => { :website => "http://rstat.us" },
        :description => "a description",
        :image => "/images/something.png"
      },
      :credentials => {:token => "1234", :secret => "4567"}
    })

    visit '/auth/facebook'
  end

  
  def log_in_facebook(u, uid = 12345)
    Author.any_instance.stubs(:valid_gravatar?).returns(:false)
    OmniAuth.config.add_mock(:facebook, {
      :uid => uid,
      :user_info => {
        :name => "Joe Public",
        :email => "jow@public.com",
        :nickname => u.username,
        :urls => { :Website => "http://rstat.us" },
        :description => "A description",
        :image => "/images/something.png"
      },
      :credentials => {:token => "1234", :secret => "4567"}
    })

    visit '/auth/facebook'
  end
  
  def log_in_email(user)
    User.stubs(:authenticate).returns(user).once
    visit "/login"
    within("form#login_form") do
      fill_in "username", :with => "anything"
      fill_in "password", :with => "anything"
    end
    click_button "Log in"
    fill_in "username", :with => "anything"
    fill_in "password", :with => "anything"

    click_button "Log in"    
  end
  
  Capybara.app = Rstatus

end
