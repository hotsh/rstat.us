ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'yaml'
require 'database_cleaner'
require 'factory_girl'

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
    OmniAuth.config.add_mock(:twitter, {
      :uid => uid,
      :user_info => {
        :name => "Joe Public",
        :nickname => u.username,
        :urls => { :Website => "http://rstat.us" },
        :description => "A description",
        :image => "/images/something.png"
      },
      :credentials => {:token => "1234", :secret => "4567"}
    })

    visit '/auth/twitter'
  end

  Capybara.app = Rstatus

end
