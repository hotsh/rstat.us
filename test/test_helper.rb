ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'yaml'
require 'database_cleaner'

require_relative '../rstatus'
