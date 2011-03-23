require 'rubygems'
require 'bundler'
Bundler.setup

require File.dirname(__FILE__) + '/rstatus'

ENV["CONSUMER_KEY"] = "thisisfake"
ENV["CONSUMER_SECRET"] = "soisthis"
ENV["APP_ID"] = "andthis"
ENV["APP_SECRET"] = "ohjoy"

run Rstatus
