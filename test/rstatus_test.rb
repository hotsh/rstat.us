require_relative 'test_helper'

class RstatusTest < MiniTest::Unit::TestCase

  include Rack::Test::Methods
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

  def test_hello_world
    get '/'
    assert last_response.ok?
  end

  def login
    get '/auth/twitter'
    follow_redirect!
    follow_redirect!
  end

  def test_login_with_twitter
    login
    assert_match /You're now logged in\./, last_response.body
  end

  def test_dashboard_page
    login
    assert_match /Update/, last_response.body
    assert_match /#{current_user.username}/, last_response.body
  end

end

