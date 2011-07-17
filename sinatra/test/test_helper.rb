require 'simplecov'
SimpleCov.start do
  add_filter "/models/all.rb"
  add_filter "/config.rb"
  add_filter "/test/"
  add_group "Models", "/models"
  add_group "Controllers", "/controllers"
  coverage_dir "/test/coverage"
end

require 'minitest/autorun'
ENV['RACK_ENV'] = 'test'
require 'bundler'
Bundler.setup
Bundler.require(:default, :test)

require_relative 'factories'
require_relative '../rstatus'

module TestHelper
  def app() Rstatus end

  def setup
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  def auth_response(username, options={})
    hsh = {
      "provider" => options[:provider] || "twitter",
      "uid" => options[:uid] || 12345,
      "user_info" => {
        "name" => "Joe Public",
        "email" => "joe@public.com",
        "nickname" => username,
        "urls" => { "Website" => "http://rstat.us" },
        "description" => "A description",
        "image" => "/images/something.png"
      },
      "credentials" => {
        "token" => options[:token] || "1234",
        "secret" => options[:secret] || "4567"
      }
    }
    return hsh
  end
end
