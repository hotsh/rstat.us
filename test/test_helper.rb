require "minitest/autorun"
require "minitest/rails"

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

MongoMapper.connection = Mongo::Connection.new('localhost')
MongoMapper.database = "rstatus-test"

require_relative "factories"

class MiniTest::Rails::Spec

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

# Uncomment to support fixtures in Model tests...
# require "active_record/fixtures"
class MiniTest::Rails::Model
  # include ActiveRecord::TestFixtures
  # self.fixture_path = File.join(Rails.root, "test", "fixtures")
end
