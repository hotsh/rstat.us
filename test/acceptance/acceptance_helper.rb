require_relative '../test_helper'

require 'rack/test'

module AcceptanceHelper
  require 'capybara/dsl'
  require 'capybara/rails'
  include Capybara::DSL
  include Rack::Test::Methods
  include TestHelper
  include ShowMeTheCookies

  OmniAuth.config.test_mode = true
  ActionController::Base.allow_forgery_protection = true

  if ENV["ENABLE_HTTPS"] == "yes"
    Capybara.app_host = 'https://example.com'
  else
    Capybara.app_host = 'http://example.com'
  end

  def app
    RstatUs::Application
  end

  def setup
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
    Capybara.reset_sessions!
    if ENV['ELASTICSEARCH_INDEX_URL']
      delete_elasticsearch_index
    end
  end

  def delete_elasticsearch_index
    begin
      RestClient.delete "#{ENV['ELASTICSEARCH_INDEX_URL']}/#{ELASTICSEARCH_INDEX_NAME}"
    rescue RestClient::ResourceNotFound
      # We don't care if we're deleting something that doesn't exist
    end
  end

  if ENV['ELASTICSEARCH_INDEX_URL']
    class ::Update
      # This makes the document searchable immediately but affects
      # performance in production.
      after_save lambda { tire.index.refresh }
    end
  end

  def omni_mock(username, options={})
    provider = (options[:provider] || :twitter).to_sym
    return OmniAuth.config.add_mock(provider, auth_response(username, options))
  end

  def omni_error_mock(message, options={})
    provider = (options[:provider] || :twitter).to_sym
    OmniAuth.config.mock_auth[provider] = message.to_sym
  end

  def log_in(user, uid = 12345, options={})
    if user.is_a? User
      user = user.username
    end

    omni_mock(user, {:uid => uid}.merge(options))

    visit '/auth/twitter'
  end

  def log_in_as_some_user(params = {:with => :twitter})
    if params[:with] == :twitter
      log_in_with_some_twitter
    elsif params[:with] == :username
      log_in_with_some_username
    end
  end

  def log_in_with_some_twitter
    @u = Fabricate(:user)
    @a = Fabricate(:authorization, :user => @u)

    log_in(@u, @a.uid)
  end

  def log_in_with_some_username
    @u = Fabricate(:user)
    log_in_username(@u)
  end

  def log_in_username(user)
    User.stubs(:authenticate).returns(user)

    visit "/login"

    within("form") do
      fill_in "username", :with => user.username
      fill_in "password", :with => "anything"
    end

    click_button "Log in"
  end

  def profile(section = nil)
    case section
    when "name"
      "#profile h3.fn"
    when "website"
      "#profile .info .website"
    when "bio"
      "#profile .info p.note"
    else
      "#profile"
    end
  end

  def flash
    "#flash"
  end

  def get_user_xrd user
    subject = "acct:#{user.username}@#{user.author.domain}"
    get "/users/#{subject}/xrd.xml"
    if last_response.status == 301
      follow_redirect!
    end

    Nokogiri.XML(last_response.body)
  end

  def logged_out?
    within "#header" do
      assert has_no_content?("Log Out")
    end
  end

  def search_for(query)
    visit "/search"
    fill_in "search", :with => query
    click_button "Search"
  end

  def heisenbug_log
    old_rails_logger = Rails.logger
    old_action_controller_logger = ActionController::Base.logger

    logfile = 'log/heisenbug.log'
    new_logger = Logger.new(logfile)
    new_logger.level = Logger::DEBUG

    Rails.logger = new_logger
    ActionController::Base.logger = new_logger

    begin
      yield
    rescue Heisenbug
      puts
      puts "Start of Heisenbug logging ======================================"
      puts File.read logfile
      puts "================"
      puts body
      puts "End of Heisenbug logging ========================================"
      puts
      puts "Congratulations!! You've seen an incidence of a HEISENBUG we're"
      puts "tracking. Please copy the output from Start to End and paste it"
      puts "in a comment on https://github.com/hotsh/rstat.us/issues/479"
    ensure
      File.delete logfile
      Rails::logger = old_rails_logger
      ActionController::Base.logger = old_action_controller_logger
    end
  end
end

class Heisenbug < StandardError; end