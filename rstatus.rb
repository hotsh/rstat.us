require 'sinatra/base'

require 'omniauth'
require 'mongo_mapper'

class Rstatus < Sinatra::Base

  configure do
    enable :sessions

    if ENV['MONGOHQ_URL']
      MongoMapper.config = {ENV['RACK_ENV'] => {'uri' => ENV['MONGOHQ_URL']}}
      MongoMapper.database = ENV['MONGOHQ_DATABASE']
      MongoMapper.connect("production")
    else
      MongoMapper.connection = Mongo::Connection.new('localhost')
      MongoMapper.database = "hackety-#{settings.environment}"
    end
  end

  use OmniAuth::Builder do
    cfg = YAML.load_file("config.yml")[ENV['RACK_ENV']]
    provider :twitter, cfg["CONSUMER_KEY"], cfg["CONSUMER_SECRET"]
  end

 get '/' do
    <<-HTML
    <a href='/auth/twitter'>Sign in with Twitter</a>
    HTML
  end

  get '/auth/twitter/callback' do
    #request.env['omniauth.auth'].to_s
    "You're now logged in."
  end

end 

