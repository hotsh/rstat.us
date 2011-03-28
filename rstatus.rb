# encoding: utf-8
# This is the source code for [rstat.us](http://rstat.us/), a microblogging 
# website built on the ostatus protocol.
#
# To get started, you'll need to install some prerequisite software:
#
# **Ruby** is used to power the site. We're currently using ruby 1.9.2p180. I
# highly reccomend that you use [rvm][rvm] to install and manage your Rubies.
# It's a fantastic tool. If you do decide to use `rvm`, you can install the 
# appropriate Ruby and create a gemset by simply `cd`-ing into the root project
# directory; I have a magical `.rvmrc` file that'll set you up.
#
# **MongoDB** is a really awesome document store. We use it to persist all of
# the data on the website. To get MongoDB, please visit their 
# [downloads page](http://www.mongodb.org/downloads) to find a package for your
# system.
#
# After installing Ruby and MongoDB, you need to aquire all of the Ruby gems
# that we use. This is pretty easy, since we're using **bundler**. Just do
# this:
#
#     $ gem install bundler
#     $ bundle install
#
# That'll set it all up! Then, you need to make sure you're running MongoDB.
# I have to open up another tab in my terminal and type
#
#     $ mongod
#
# to get this to happen. When you're done hacking, you can hit ^-c to stop
# `mongod` from running.
#
# To actually start up the site, just 
#
#     $ rackup
#
# and then visit [http://localhost:9292/](http://localhost:9292). You're good
# to go!
# 
# [rvm]: http://rvm.beginrescueend.com/

#### About rstatus.rb
#
# This file is the main entry point to the application. It has three main
# purposes:
#
# 1. Include all relevant gems and library code.
# 2. Configure all settings based on our environment.
# 3. Set up a few basic routes.
#
# Everything else is handled by code that's included from this file.

#### Including gems

# We need to require rubygems and bundler to get things going. Then we call
# `Bundler.setup` to get all of the magic started.
require 'bundler'
Bundler.require

# We moved lots of helpers into a separate file. These are all things that are
# useful throughout the rest of the application.
require_relative "helpers"

# It's good form to make your Sinatra applications be a subclass of Sinatra::Base.
# This way, we're not polluting the global namespace with our methods and routes
# and such.
class Rstatus < Sinatra::Base; end;

require_relative "config"

class Rstatus

  # EMPTY USERNAME HANDLING - quick and dirty
  before do
    @error_bar = ""
    if current_user && (current_user.username.nil? or current_user.username.empty? or !current_user.username.match(/profile.php/).nil?)
      @error_bar = haml :_username_error, :layout => false
    end
  end

  get '/reset-username' do
    unless current_user.nil? || current_user.username.empty?
      redirect "/"
    end

    haml :reset_username
  end

  post '/reset-username' do
    exists = User.first :username => params[:username]
    if !params[:username].nil? && !params[:username].empty? && exists.nil?
      if current_user.reset_username(params)
        flash[:notice] = "Thank you for updating your username"
      else
        flash[:notice] = "Your username could not be updated"
      end
      redirect "/"
    else
      flash[:notice] = "Sorry, that username has already been taken or is not valid. Please try again."
      haml :reset_username
    end
  end

  get '/' do
    if logged_in?
      set_params_page
      @updates = current_user.timeline(params)
      set_next_prev_page if @updates.total_entries > params[:per_page]

      @timeline = true

      if params[:reply]
        u = Update.first(:id => params[:reply])
        @update_text = "@#{u.author.username} "
        @update_id = u.id
      elsif params[:share]
        u = Update.first(:id => params[:share])
        @update_text = "RS @#{u.author.username}: #{u.text}"
        @update_id = u.id
      else
        @update_text = ""
        @update_id = ""
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
    cache_control :public, :must_revalidate, :max_age => 60
    haml :index, :layout => false
  end

  # get '/screen.css' do
  #   cache_control :public, :must_revalidate, :max_age => 360
  #   scss(:screen, Compass.sass_engine_options)
  # end

  get '/replies' do
    if logged_in?
      set_params_page
      @replies = current_user.at_replies(params)
      set_next_prev_page if @replies.total_entries > params[:per_page]
      haml :replies
    else
      haml :index, :layout => false
    end
  end

  get '/auth/:provider/callback' do
    auth = request.env['omniauth.auth']
    unless @auth = Authorization.find_from_hash(auth)
      if logged_in?
        Authorization.create_from_hash(auth, uri("/"), current_user)
        redirect "/users/#{current_user.username}/edit"
      else
        session[:uid] = auth['uid']
        session[:provider] = auth['provider']
        session[:name] = auth['user_info']['name']
        session[:nickname] = auth['user_info']['nickname']
        session[:website] = auth['user_info']['urls']['Website']
        session[:description] = auth['user_info']['description']
        session[:image] = auth['user_info']['image']
        session[:email] = auth['user_info']['email']
        #let's store their oauth stuff so they don't have to re-login after
        session[:oauth_token] = auth['credentials']['token']
        session[:oauth_secret] = auth['credentials']['secret']

        ## We can probably get rid of this since the user confirmation will check for duplicate usernames [brimil01]
        if User.first :username => auth['user_info']['nickname'] or auth['user_info']['nickname'] =~ /profile[.]php[?]id=/
          #we have a username conflict!
          flash[:notice] = "Sorry, someone has that name."
          redirect '/users/new'
          return
        else
          # Redirect to confirm page to verify username and provide email
          redirect '/users/confirm'
          return
        end
      end
    end

    ## Lets store the tokens if they don't alreay exist
    if @auth.oauth_token.nil?
      @auth.oauth_token = auth['credentials']['token']
      @auth.oauth_secret = auth['credentials']['secret']
      @auth.nickname = auth['user_info']['nickname']
      @auth.save
    end

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

  get '/users/confirm' do
    haml :"users/confirm"
  end

  get '/users/new' do
    haml :"users/new"
  end

  get '/users' do
    set_params_page

    # Filter users by search params
    if params[:search] && !params[:search].empty?
      @users = User.where(:username => /#{params[:search]}/i)

    # Filter users by letter
    elsif params[:letter]
      if params[:letter] == "other"
        @users = User.where(:username => /^[^a-z0-9]/i)
      elsif
        @users = User.where(:username => /^#{params[:letter][0].chr}/i)
      end
    else
      @users = User
    end

    # Sort users alphabetically when filtering by letter
    if params[:letter]
      @users = @users.sort(:username.desc)
    else
      @users = @users.sort(:created_at.desc)
    end

    @users = @users.paginate(:page => params[:page], :per_page => params[:per_page])

    @next_page = nil
    set_next_prev_page

    haml :"users/index"
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
      auth['user_info']['email'] = session[:email]
      auth['credentials'] = {}
      auth['credentials']['token'] = session[:oauth_token]
      auth['credentials']['secret'] = session[:oauth_secret]

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
    if logged_in?
      session[:user_id] = nil
      flash[:notice] = "You've been logged out."
    end
    redirect '/'
  end

  # show user profile
  get "/users/:slug" do
    set_params_page

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
    set_next_prev_page

    haml :"users/show"
  end

  # subscriber receives updates
  # should be 'put', PuSH sucks at REST
  #post "/feeds/:id.atom" do
  #  feed = Feed.first :id => params[:id]
  #  feed.update_entries(request.body.read, request.url, url(feed.url), request.env['HTTP_X_HUB_SIGNATURE'])
  #end

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
    end

    # follow them!
    f = current_user.follow! feed_url
    unless f
      flash[:notice] = "There was a problem following #{params[:url]}."
      redirect request.referrer
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
      #sub = OSub::Subscription.new(request.url, feed.url, nil, feed.verify_token)

      # perform the hub's challenge
      #respond = sub.perform_challenge(params['hub.challenge'])

      # verify that the random token is the same as when we
      # subscribed with the hub initially and that the topic
      # url matches what we expect
      #verified = params['hub.topic'] == feed.url
      #if verified and sub.verify_subscription(params['hub.verify_token'])
      #  if development?
      #    puts "Verified"
      #  end
      #  body respond[:body]
      #  status respond[:status]
      #else
      #  if development?
      #    puts "Verification Failed"
      #  end
        # if the verification fails, the specification forces us to
        # return a 404 status
        status 404
      #end
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
      if @user.edit_user_profile(params)
        flash[:notice] = "Profile saved!"
      else
        flash[:notice] = "Profile could not be saved!"
      end
      redirect "/users/#{params[:username]}"

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
    set_params_page

    feeds = User.first(:username => params[:name]).following

    @users = feeds.paginate(:page => params[:page], :per_page => params[:per_page], :order => :id.desc).map{|f| f.author.user}

    set_next_prev_page
    @next_page = nil unless params[:page]*params[:per_page] < feeds.count

    haml :"users/list", :locals => {:title => "Following"}
  end

  get '/users/:name/following.json' do
    set_params_page

    users = User.first(:username => params[:name]).following
    authors = users.map { |user| user.author }
    authors.to_a.to_json
  end

  get '/users/:name/followers' do
    set_params_page

    feeds = User.first(:username => params[:name]).followers

    @users = feeds.paginate(:page => params[:page], :per_page => params[:per_page], :order => :id.desc).map{|f| f.author.user}

    set_next_prev_page
    @next_page = nil unless params[:page]*params[:per_page] < feeds.count

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
    do_tweet = params[:tweet] == "1"
    do_facebook = params[:facebook] == "1"
    u = Update.new(:text => params[:text],
                   :referral_id => params[:referral_id],
                   :author => current_user.author,
                   :twitter => do_tweet,
                   :facebook => do_facebook)

    # and entry to user's feed
    current_user.feed.updates << u
    current_user.feed.save
    current_user.save

    # tell hubs there is a new entry
    current_user.feed.ping_hubs(url(current_user.feed.url))

    if params[:text].length < 1
      flash[:notice] = "Your status is too short!"
    elsif params[:text].length > 140
      flash[:notice] = "Your status is too long!"
    else
      flash[:notice] = "Update created."
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

  get "/search" do
    @updates = []
    if params[:q]
      @updates = Update.filter(params[:q], :page => params[:page], :per_page => params[:per_page] || 20, :order => :created_at.desc)
    end

    @next_page = nil
    @prev_page = nil

    if !@updates.empty? && @updates.next_page
      @next_page = "?#{Rack::Utils.build_query :page => @updates.next_page}"
    end
    if !@updates.empty? && @updates.previous_page
      @prev_page = "?#{Rack::Utils.build_query :page => @updates.previous_page}"
    end
    haml :search
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
    if logged_in?
      redirect '/'
    else
      haml :"login"
    end
  end

  post "/login" do
    u = User.first :username => params[:username]
    if u.nil?
      #signup
      user = User.new params
      if user.save
        session[:user_id] = user.id
        flash[:notice] = "Thanks for signing up!"
        redirect "/"
      else
        puts "not saved"
        flash[:notice] = "There was a problem... can you pick a different username?"
        redirect "/login"
      end
    else
      #login
      if user = User.authenticate(params[:username], params[:password])
        session[:user_id] = user.id
        flash[:notice] = "Login successful."
        redirect "/"
      else
        flash[:notice] = "The username or password you entered was incorrect"
        redirect "/login"
      end
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
    haml :'error', :layout => false, :locals => {:code => 404, :message => "We couldn't find the page you're looking for"}
  end

  error do
    haml :'error', :layout => false, :locals => {:code => 500, :message => "Something went wrong"}
  end

  get "/hashtags/:tag" do
    @hashtag = params[:tag]
    set_params_page
    @updates = Update.hashtag_search(@hashtag, params)
    set_next_prev_page if @updates.total_entries > params[:per_page]
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
