require 'bundler'
Bundler.require

require_relative 'models/all'

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

  set :port, 8088


  # The `PONY_VIA_OPTIONS` hash is used to configure `pony`. Basically, we only
  # want to actually send mail if we're in the production environment. So we set
  # the hash to just be `{}`, except when we want to send mail.
  configure :test do
    PONY_VIA_OPTIONS = {}
  end

  configure :development do
    PONY_VIA_OPTIONS = {}
  end

  configure :production do
    require 'newrelic_rpm'
  end
  

  # We're using [SendGrid](http://sendgrid.com/) to send our emails. It's really
  # easy; the Heroku addon sets us up with environment variables with all of the
  # configuration options that we need.
  configure :production do
    PONY_VIA_OPTIONS =  {
      :address        => "smtp.sendgrid.net",
      :port           => "25",
      :authentication => :plain,
      :user_name      => ENV['SENDGRID_USERNAME'],
      :password       => ENV['SENDGRID_PASSWORD'],
      :domain         => ENV['SENDGRID_DOMAIN']
    }
  end

  use Rack::Session::Cookie, :secret => ENV['COOKIE_SECRET']
  set :root, File.dirname(__FILE__)
  set :haml, :escape_html => true
  set :method_override, true

  require 'rack-flash'
  use Rack::Flash

  configure do
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
    provider :twitter, ENV["CONSUMER_KEY"], ENV["CONSUMER_SECRET"]
    provider :facebook, ENV["APP_ID"], ENV["APP_SECRET"]
  end

  get '/' do
    if logged_in?

      params[:page] ||= 1
      params[:per_page] ||= 25
      params[:page] = params[:page].to_i
      params[:per_page] = params[:per_page].to_i

      @next_page = "?#{Rack::Utils.build_query :page => params[:page] + 1}"

      if params[:page] > 1
        @prev_page = "?#{Rack::Utils.build_query :page => params[:page] - 1}"
      end

      @updates = current_user.timeline(params)

      @timeline = true

      @update_text = ""
      @update_id = ""
      if params[:reply]
        u = Update.first(:id => params[:reply])
        @update_text = "@#{u.author.username} "
        @update_id = u.id
      elsif params[:share]
        u = Update.first(:id => params[:share])
        @update_text = "RS @#{u.author.username}: #{u.text}"
        @update_id = u.id
      end

      if params[:status]
        @update_text = @update_text + params[:status]
      end

      haml :dashboard
    else
      haml :index, :layout => false
    end
  end

  get '/home' do
    haml :index, :layout => false
  end

  get '/replies' do
    if logged_in?
      params[:page] ||= 1
      params[:per_page] ||= 25
      params[:page] = params[:page].to_i
      params[:per_page] = params[:per_page].to_i

      @next_page = "?#{Rack::Utils.build_query :page => params[:page] + 1}"

      if params[:page] > 1
        @prev_page = "?#{Rack::Utils.build_query :page => params[:page] - 1}"
      end

      @replies = current_user.at_replies(params)
      haml :replies
    else
      haml :index, :layout => false
    end
  end

  get '/auth/:provider/callback' do
    auth = request.env['omniauth.auth']
    unless @auth = Authorization.find_from_hash(auth)
      if User.first :username => auth['user_info']['nickname']
        #we have a username conflict!

        #let's store their oauth stuff so they don't have to re-login after
        session[:oauth_token] = auth['credentials']['token']
        session[:oauth_secret] = auth['credentials']['secret']

        session[:uid] = auth['uid']
        session[:provider] = auth['provider']
        session[:name] = auth['user_info']['name']
        session[:nickname] = auth['user_info']['nickname']
        session[:website] = auth['user_info']['urls']['Website']
        session[:description] = auth['user_info']['description']
        session[:image] = auth['user_info']['image']

        flash[:notice] = "Sorry, someone has that name."
        redirect '/users/new'
        return
      else
        @auth = Authorization.create_from_hash(auth, uri("/"), current_user)
      end
    end

    session[:oauth_token] = auth['credentials']['token']
    session[:oauth_secret] = auth['credentials']['secret']
    session[:user_id] = @auth.user.id

    flash[:notice] = "You're now logged in."
    redirect '/'
  end

  get '/auth/failure' do
    if params[:message] == "invalid_credentials"
      haml :"signup/invalid_credentials"
    else
      raise Sinatra::NotFound
    end
  end

  get '/users/new' do
    haml :"users/new"
  end

  post '/users' do
    user = User.new params
    if user.save
      #this is really stupid.
      auth = {}
      auth['uid'] = session[:uid]
      auth['provider'] = session[:provider]
      auth['user_info'] = {}
      auth['user_info']['name'] = session[:name]
      auth['user_info']['nickname'] = session[:nickname]
      auth['user_info']['urls'] = {}
      auth['user_info']['urls']['Website'] = session[:website]
      auth['user_info']['description'] = session[:description]
      auth['user_info']['image'] = session[:image]

      Authorization.create_from_hash(auth, uri("/"), user)

      flash[:notice] = "Thanks! You're all signed up with #{user.username} for your username."
      session[:user_id] = user.id
      redirect '/'
    else
      flash[:notice] = "Oops! That username was taken. Pick another?"
      redirect '/users/new'
    end
  end

  get "/logout" do
    session[:user_id] = nil
    flash[:notice] = "You've been logged out."
    redirect '/'
  end

  # show user profile
  get "/users/:slug" do
    params[:page] ||= 1
    params[:per_page] ||= 20
    params[:page] = params[:page].to_i
    params[:per_page] = params[:per_page].to_i

    user = User.first :username => params[:slug]
    if user.nil?
      raise Sinatra::NotFound
    end
    @author = user.author
    #XXX: the following doesn't work for some reasond
    # @updates = user.feed.updates.sort{|a, b| b.created_at <=> a.created_at}.paginate(:page => params[:page], :per_page => params[:per_page])

    #XXX: this is not webscale
    @updates = Update.where(:feed_id => user.feed.id).order(['created_at', 'descending']).paginate(:page => params[:page], :per_page => params[:per_page])

    @next_page = nil
    @prev_page = nil

    @next_page = "?#{Rack::Utils.build_query :page => params[:page] + 1}"

    if params[:page] > 1
      @prev_page = "?#{Rack::Utils.build_query :page => params[:page] - 1}"
    end

    haml :"users/show"
  end

  # subscriber receives updates
  # should be 'put', PuSH sucks at REST
  post "/feeds/:id.atom" do
    feed = Feed.first :id => params[:id]
    feed.update_entries(request.body.read, request.url, url(feed.url), request.env['HTTP_X_HUB_SIGNATURE'])
  end

  # unsubscribe from a feed
  delete '/subscriptions/:id' do
    require_login! :return => request.referrer

    feed = Feed.first :id => params[:id]

    @author = feed.author
    redirect request.referrer if @author.user == current_user

    #make sure we're following them already
    unless current_user.following? feed.url
      flash[:notice] = "You're not following #{@author.username}."
      redirect request.referrer
      return
    end

    #unfollow them!
    current_user.unfollow! feed

    flash[:notice] = "No longer following #{@author.username}."
    redirect request.referrer
  end

  post "/subscriptions" do
    require_login! :return => request.referrer

    feed_url = nil

    # Allow for a variety of feed addresses
    case params[:url]
    when /^feed:\/\//
      feed_url = "http" + params[:url][4..-1]
    when /@/

      # TODO: ensure caching of finger lookup.
      acct = Redfinger.finger(params[:url])
      feed_url = acct.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }

    else

      feed_url = params[:url]
    end

    #make sure we're not following them already
    if current_user.following? feed_url
      # which means it exists
      feed = Feed.first(:remote_url => feed_url)
      if feed.nil? and feed_url[0] == "/"
        feed_id = feed_url[/^\/feeds\/(.+)$/,1]
        feed = Feed.first(:id => feed_id)
      end

      flash[:notice] = "You're already following #{feed.author.username}."

      redirect request.referrer

      return
    end

    # follow them!

    f = current_user.follow! feed_url
    unless f
      flash[:notice] = "The was a problem following #{params[:url]}."
      redirect request.referrer
      return
    end

    if not f.local?

      # remote feeds require some talking to a hub
      hub_url = f.hubs.first

      sub = OSub::Subscription.new(url("/feeds/#{f.id}.atom"), f.url, f.secret)
      sub.subscribe(hub_url, f.verify_token)

      name = f.author.username
      flash[:notice] = "Now following #{name}."
      redirect request.referrer
    else
      # local feed... redirect to that user's profile
      flash[:notice] = "Now following #{f.author.username}."
      redirect request.referrer
    end
  end

  # publisher will feed the atom to a hub
  # subscribers will verify a subscription
  get "/feeds/:id.atom" do
    content_type "application/atom+xml"

    feed = Feed.first :id => params[:id]

    if params['hub.challenge']
      sub = OSub::Subscription.new(request.url, feed.url, nil, feed.verify_token)

      # perform the hub's challenge
      respond = sub.perform_challenge(params['hub.challenge'])

      # verify that the random token is the same as when we
      # subscribed with the hub initially and that the topic
      # url matches what we expect
      verified = params['hub.topic'] == feed.url
      if verified and sub.verify_subscription(params['hub.verify_token'])
        if development?
          puts "Verified"
        end
        body respond[:body]
        status respond[:status]
      else
        if development?
          puts "Verification Failed"
        end
        # if the verification fails, the specification forces us to
        # return a 404 status
        status 404
      end
    else
      # TODO: Abide by headers that supply cache information
      body feed.atom(uri("/"))
    end
  end

  # user edits own profile
  get "/users/:username/edit" do
    @user = User.first :username => params[:username]
    if @user == current_user
      haml :"users/edit"
    else
      redirect "/users/#{params[:username]}"
    end
  end

  # user updates own profile
  put "/users/:username" do
    @user = User.first :username => params[:username]
    if @user == current_user
      @user.author.name    = params[:name]
      @user.author.email   = params[:email]
      @user.author.website = params[:website]
      @user.author.bio     = params[:bio]
      @user.author.save
      flash[:notice] = "Profile saved!"
      redirect "/users/#{params[:username]}"
      return
    else
      redirect "/users/#{params[:username]}"
    end
  end

  # an alias for the route of the feed
  get "/users/:name/feed" do
    feed = User.first(:username => params[:name]).feed
    redirect "/feeds/#{feed.id}.atom"
  end

  # This lets us see who is following.
  get '/users/:name/following' do
    params[:page] ||= 1
    params[:per_page] ||= 20
    params[:page] = params[:page].to_i
    params[:per_page] = params[:per_page].to_i
    feeds = User.first(:username => params[:name]).following

    @users = feeds.paginate(:page => params[:page], :per_page => params[:per_page])

    @next_page = nil
    @prev_page = nil

    if params[:page]*params[:per_page] < feeds.count
      @next_page = "?#{Rack::Utils.build_query :page => params[:page] + 1}"
    end

    if params[:page] > 1
      @prev_page = "?#{Rack::Utils.build_query :page => params[:page] - 1}"
    end

    haml :"users/list", :locals => {:title => "Following"}
  end

  get '/users/:name/followers' do
    params[:page] ||= 1
	params[:per_page] ||= 20
    params[:page] = params[:page].to_i
    params[:per_page] = params[:per_page].to_i
    feeds = User.first(:username => params[:name]).followers
    
    @users = feeds.paginate(:page => params[:page], :per_page => params[:per_page])
	
    @next_page = nil
    @prev_page = nil

    if params[:page]*params[:per_page] < feeds.count
	  @next_page = "?#{Rack::Utils.build_query :page => params[:page] + 1}"
    end
    
    if params[:page] > 1
	  @prev_page = "?#{Rack::Utils.build_query :page => params[:page] - 1}"
    end


    haml :"users/list", :locals => {:title => "Followers"}
  end

  get '/updates' do
    @updates = Update.paginate( :page => params[:page], :per_page => params[:per_page] || 20, :order => :created_at.desc)

    if @updates.next_page
          @next_page = "?#{Rack::Utils.build_query :page => @updates.next_page}"
    end

    if @updates.previous_page
          @prev_page = "?#{Rack::Utils.build_query :page => @updates.previous_page}"
    end

    haml :world
  end

  post '/updates' do
    u = Update.new(:text => params[:text],
                   :referral_id => params[:referral_id], 
                   :author => current_user.author,
                   :oauth_token => session[:oauth_token],
                   :oauth_secret => session[:oauth_secret])

    # and entry to user's feed
    current_user.feed.updates << u
    current_user.feed.save
    current_user.save
    
    # tell hubs there is a new entry
    current_user.feed.ping_hubs(url(current_user.feed.url))

    if params[:text].length >= 1 and params[:text].length <= 140
      flash[:notice] = "Update created."
    else
      flash[:notice] = "Unable to save update."
    end

    redirect "/"
  end

  get '/updates/:id' do
    @update = Update.first :id => params[:id]
    @referral = @update.referral
    haml :"updates/show", :layout => :'updates/layout'
  end

  post '/signup' do
    u = User.create(:email => params[:email], 
                    :status => "unconfirmed")
    u.set_perishable_token

    if development?
      puts uri("/") + "confirm/#{u.perishable_token}"
    else
      Notifier.send_signup_notification(params[:email], u.perishable_token)
    end

    haml :"signup/thanks"
  end

  get "/confirm/:token" do
    @user = User.first :perishable_token => params[:token]
    # XXX: Handle user being nil (invalid confirmation)
    @username = @user.email.match(/^([^@]+?)@/)[1]

    @valid_username = false
    unless User.first :username => @username
      @valid_username = true
    end

    haml :"signup/confirm"
  end

  post "/confirm" do
    user = User.first :perishable_token => params[:perishable_token]
    user.username = params[:username]
    user.password = params[:password]
    user.status = "confirmed"
    user.author = Author.create(:username => user.username,
                                :email => user.email)

    # propagate the authorship to their feed as well
    user.feed.author = user.author
    user.feed.save

    user.save
    session[:user_id] = user.id.to_s

    flash[:notice] = "Thanks for signing up!"
    redirect '/'
  end

  get "/login" do
    haml :"login"
  end

  post "/login" do
    if user = User.authenticate(params[:username], params[:password])
      session[:user_id] = user.id
      flash[:notice] = "Login successful."
      redirect "/"
    else
      flash[:notice] = "The username or password you entered was incorrect"
      redirect "/login"
    end
  end

  delete '/updates/:id' do |id|
    update = Update.first :id => params[:id]

    if update.author == current_user.author
      update.destroy

      flash[:notice] = "Update Baleeted!"
      redirect "/"
    else
      flash[:notice] = "I'm afraid I can't let you do that, " + current_user.name + "."
      redirect back
    end
  end

  not_found do
    haml :'404', :layout => false
  end

  get "/hashtags/:tag" do
    @hashtag = params[:tag]
    params[:page] ||= 1
    params[:per_page] ||= 25
    params[:page] = params[:page].to_i
    params[:per_page] = params[:per_page].to_i

    @next_page = "?#{Rack::Utils.build_query :page => params[:page] + 1}"

    if params[:page] > 1
      @prev_page = "?#{Rack::Utils.build_query :page => params[:page] - 1}"
    end
    @updates = Update.hashtag_search(@hashtag, params)
    @timeline = true
    @update_text = params[:status]
    haml :dashboard
  end

  get "/open_source" do
    haml :opensource
  end

  get "/follow" do
    haml :external_subscription
  end

  get "/contact" do
    haml :contact
  end

end

