require 'rubygems'
require 'bundler'
Bundler.setup

require File.dirname(__FILE__) + '/rstatus'

unless ENV['RACK_ENV'] == "production"
  config = YAML.load_file('config.yml')[ENV['RACK_ENV']]

  config.each do |key, value|
    ENV[key] = value
  end
end

run Rstatus
