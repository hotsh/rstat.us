ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'yaml'
require 'database_cleaner'

require_relative '../rstatus'

module TestHelper
  include Rack::Test::Methods
  include Sinatra::UserHelper

  OmniAuth.config.test_mode = true
  OmniAuth.config.add_mock(:twitter, {
    :uid => '12345',
    :user_info => {
      :name => "Joe Public",
      :nickname => "joepublic",
      :urls => { :Website => "http://rstat.us" },
      :description => "A description",
      :image => "/images/something.png"
    }
  })

  def app() Rstatus end

  def setup
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  def login
    get '/auth/twitter'
    follow_redirect!
    follow_redirect!
  end
end

