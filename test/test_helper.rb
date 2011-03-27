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

  def log_in(u, uid = 12345)
    Author.any_instance.stubs(:valid_gravatar?).returns(:false)
    OmniAuth.config.add_mock(:twitter, {
      :uid => uid,
      :user_info => {
        :name => "Joe Public",
        :nickname => u.username,
        :urls => { :website => "http://rstat.us" },
        :description => "a description",
        :image => "/images/something.png"
      },
      :credentials => {:token => "1234", :secret => "4567"}
    })

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

  Capybara.app = Rstatus

end
