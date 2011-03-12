require 'sinatra/base'

require 'omniauth'
require 'mongo_mapper'

require_relative 'models'

class Rstatus < Sinatra::Base

  configure do
    enable :sessions

    if ENV['MONGOHQ_URL']
      MongoMapper.config = {ENV['RACK_ENV'] => {'uri' => ENV['MONGOHQ_URL']}}
      MongoMapper.database = ENV['MONGOHQ_DATABASE']
      MongoMapper.connect("production")
    else
      MongoMapper.connection = Mongo::Connection.new('localhost')
      MongoMapper.database = "rstatus-#{settings.environment}"
    end
  end

  helpers do
    def current_user
      @current_user ||= User.first(:id => session[:user_id])
    end

    def signed_in?
      !!current_user
    end

    def current_user=(user)
      @current_user = user
      session[:user_id] = user.id
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

    auth = request.env['omniauth.auth']
    unless @auth = Authorization.find_from_hash(auth)
      @auth = Authorization.create_from_hash(auth, current_user)
    end
    self.current_user = @auth.user

    "You're now logged in."
  end

end 

