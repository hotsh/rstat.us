require "minitest/autorun"
require "webmock/test_unit"

ENV["RAILS_ENV"] = "test"
begin
  require File.expand_path('../../config/environment', __FILE__)
  MongoMapper.connection = Mongo::Connection.new('localhost')
  MongoMapper.database = "rstatus-test"
rescue Mongo::ConnectionFailure => e
  puts <<-DERPMSG

  *DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*
  *
  *  Whoops! It looks like mongo isn't running on this machine.
  *  Please check the following:
  *
  *  1. Is Mongo installed? (http://www.mongodb.org/)
  *
  *  2. Is `mongod` running? <<<<<<<<<<<<<<<<<<<< MOST COMMON PROBLEM
  *
  *  3. Have you done anything custom that would warrant a change to the
  *     config in test/test_helper.rb? (You probably haven't)
  *
  *DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*DERP*

  DERPMSG
  exit 1
end

require_relative "factories"

module TestHelper
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

# Mock Pony for mail delivery
module Pony
  def self.deliveries
    @deliveries ||= []
  end

  def self.mail(options)
    deliveries << build_mail(options)
  end
end

