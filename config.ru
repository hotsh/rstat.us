require 'rubygems'
require 'bundler/setup'

require File.dirname(__FILE__) + '/rstatus'

unless ENV['RACK_ENV'] == "production"
  config = YAML.load_file('config/config.yml')[ENV['RACK_ENV']]

  config.each do |key, value|
    ENV[key] = value
  end
else
  require 'exceptional'
  use Rack::Exceptional, ENV['EXCEPTIONAL_KEY']
end

run Rstatus
