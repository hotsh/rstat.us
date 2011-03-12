require "rubygems"
require 'bundler'
Bundler.setup

require 'sinatra/base'

class Rstatus < Sinatra::Base

  get '/' do
     'Hello, world!'
  end

end 

