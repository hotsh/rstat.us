require 'sinatra/base'
require 'sinatra/reloader'

require 'omniauth'
require 'mongo_mapper'
require 'haml'
require 'time-ago-in-words'
require 'sinatra/content_for'
require 'twitter'

require_relative 'models'

module Sinatra
  module UserHelper

    # This incredibly useful helper gives us the currently logged in user. We
    # keep track of that by just setting a session variable with their id. If it
    # doesn't exist, we just want to return nil.
    def current_user
      return User.first(:id => session[:user_id]) if session[:user_id]
      nil
    end

    # This very simple method checks if we've got a logged in user. That's pretty
    # easy: just check our current_user.
    def logged_in?
      current_user != nil
    end

    # Our `admin_only!` helper will only let admin users visit the page. If
    # they're not an admin, we redirect them to either / or the page that we
    # specified when we called it.
    def admin_only!(opts = {:return => "/"})
      unless logged_in? && current_user.admin?
        flash[:error] = "Sorry, buddy"
        redirect opts[:return]
      end
    end

    # Similar to `admin_only!`, `require_login!` only lets logged in users access
    # a particular page, and redirects them if they're not.
    def require_login!(opts = {:return => "/"})
      unless logged_in?
        flash[:error] = "Sorry, buddy"
        redirect opts[:return]
      end
    end
  end

  helpers UserHelper
end


class Rstatus < Sinatra::Base
  use Rack::Session::Cookie, :secret => ENV['COOKIE_SECRET']
  set :root, File.dirname(__FILE__)
  set :haml, :escape_html => true
  set :config, YAML.load_file("config.yml")[ENV['RACK_ENV']]

  require 'rack-flash'
  use Rack::Flash

  configure :development do
    register Sinatra::Reloader
  end

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
  helpers Sinatra::ContentFor

  helpers do
    [:development, :production, :test].each do |environment|
      define_method "#{environment.to_s}?" do
        return settings.environment == environment.to_sym
      end
    end
  end

  use OmniAuth::Builder do
    provider :twitter, Rstatus.settings.config["CONSUMER_KEY"], Rstatus.settings.config["CONSUMER_SECRET"]
    provider :facebook, Rstatus.settings.config["APP_ID"], Rstatus.settings.config["APP_SECRET"]
  end

  get '/' do
    if logged_in?
      haml :dashboard
    else
      haml :index, :layout => false
    end
  end

  get '/replies' do
    if logged_in?
      haml :replies
    else
      haml :index, :layout => false
    end
  end

  get '/auth/:provider/callback' do
    puts "foo"
    auth = request.env['omniauth.auth']
    unless @auth = Authorization.find_from_hash(auth)
      @auth = Authorization.create_from_hash(auth, current_user)
    end

    session[:oauth_token] = auth['credentials']['token']
    session[:oauth_secret] = auth['credentials']['secret']
    session[:user_id] = @auth.user.id

    flash[:notice] = "You're now logged in."
    redirect '/'
  end

  get "/logout" do
    session[:user_id] = nil
    flash[:notice] = "You've been logged out."
    redirect '/'
  end

  get "/users/:slug" do
    @user = User.first :username => params[:slug]
    haml :"users/show"
  end

  # users can follow each other, and this route takes care of it!
  get '/users/:name/follow' do
    require_login! :return => "/users/#{params[:name]}/follow"

    @user = User.first(:username => params[:name])
    redirect "/users/#{@user.username}" and return if @user == current_user

    #make sure we're not following them already
    if current_user.following? @user
      flash[:notice] = "You're already following #{params[:name]}."
      redirect "/users/#{@user.username}"
      return
    end

    # then follow them!
    current_user.follow! @user

    flash[:notice] = "Now following #{params[:name]}."
    redirect "/users/#{@user.username}"
  end

  #this lets you unfollow a user
  get '/users/:name/unfollow' do
    require_login! :return => "/users/#{params[:name]}/unfollow"

    @user = User.first(:username => params[:name])
    redirect "/users/#{@user.username}" and return if @user == current_user

    #make sure we're following them already
    unless current_user.following? @user
      flash[:notice] = "You're not following #{params[:name]}."
      redirect "/users/#{@user.username}"
      return
    end

    #unfollow them!
    current_user.unfollow! @user

    flash[:notice] = "No longer following #{params[:name]}."
    redirect "/users/#{@user.username}"
  end

  # this lets us see followers.
  get '/users/:name/followers' do
    @user = User.first(:username => params[:name])

    haml :"users/followers"
  end

  # This lets us see who is following.
  get '/users/:name/following' do
    @user = User.first(:username => params[:name])
    haml :"users/following"
  end

  post '/updates' do
    update = Update.new(:text => params[:text], 
                        :oauth_secret => session[:oauth_secret],
                        :oauth_token => session[:oauth_token])
    update.user = current_user
    update.save

    flash[:notice] = "Update created."
    redirect "/"
  end

  get '/updates/:id' do
    @update = Update.first :id => params[:id]
    haml :"updates/show", :layout => :'updates/layout'
  end

  not_found do
    haml :'404', :layout => false
  end

end

