require 'sinatra/base'

require 'omniauth'
require 'mongo_mapper'
require 'haml'

require_relative 'models'

module Sinatra
  module UserHelper
    def current_user
      @current_user ||= User.first(:id => session[:user_id])
    end

    def logged_in?
      !!current_user
    end

    def current_user=(user)
      @current_user = user
      session[:user_id] = user.id
    end
  end

  helpers UserHelper
end


class Rstatus < Sinatra::Base
  use Rack::Session::Cookie, :secret => ENV['COOKIE_SECRET']

  require 'rack-flash'
  use Rack::Flash

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

  helpers Sinatra::UserHelper
  

  use OmniAuth::Builder do
    cfg = YAML.load_file("config.yml")[ENV['RACK_ENV']]
    provider :twitter, cfg["CONSUMER_KEY"], cfg["CONSUMER_SECRET"]
  end

 get '/' do
   if logged_in?
     haml :dashboard
   else
    <<-HTML
    <a href='/auth/twitter'>Sign in with Twitter</a>
    HTML
   end
  end

  get '/auth/twitter/callback' do

    auth = request.env['omniauth.auth']
    unless @auth = Authorization.find_from_hash(auth)
      @auth = Authorization.create_from_hash(auth, current_user)
    end
    self.current_user = @auth.user

    flash[:notice] = "You're now logged in."
    redirect '/'
  end

  get "/logout" do
    session[:user_id] = nil
    flash[:notice] = "You've been logged out."
    redirect '/'
  end

end 

