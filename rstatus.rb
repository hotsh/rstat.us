# encoding: utf-8
# This is the source code for [rstat.us](http://rstat.us/), a microblogging
# website built on the ostatus protocol.
#
# To get started, you'll need to install some prerequisite software:
#
# **Ruby** is used to power the site. We're currently using ruby 1.9.2p180. I
# highly recommend that you use [rvm][rvm] to install and manage your Rubies.
# It's a fantastic tool. If you do decide to use `rvm`, you can install the
# appropriate Ruby and create a gemset by simply `cd`-ing into the root project
# directory; I have a magical `.rvmrc` file that'll set you up.
#
# **MongoDB** is a really awesome document store. We use it to persist all of
# the data on the website. To get MongoDB, please visit their
# [downloads page](http://www.mongodb.org/downloads) to find a package for your
# system.
#
# After installing Ruby and MongoDB, you need to acquire all of the Ruby gems
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
# If you want to contribute to rstatus you will have to run the tests before you
# send a pull request. You can do so by calling
#
#    $ rake test
#
# in the rstat.us root directory. Once your changes pass all tests you may commit
# and send a pull request via Github.
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

# It's good form to make your Sinatra applications be a subclass of
#Sinatra::Base. This way, we're not polluting the global namespace with our
#methods and routes and such.
class Rstatus < Sinatra::Base; end;

require_relative "config/config"

Dir.glob("controllers/*.rb").each { |r| require_relative r }

class Rstatus

  get '/' do
    if logged_in?
      call! env.merge("PATH_INFO" => '/timeline')
    else
      haml :"static/home", :layout => false
    end
  end

  get '/home' do
    cache_control :public, :must_revalidate, :max_age => 60
    haml :"static/home", :layout => false
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
  
  get "/hashtags/:tag" do
    @hashtag = params[:tag]
    set_params_page
    @updates = Update.hashtag_search(@hashtag, params)
    set_pagination_buttons(@updates)
    @timeline = true
    @update_text = params[:status]
    haml :"updates/index"
  end

  not_found do
    haml :"static/error", :layout => false, :locals => {:code => 404, :message => "We couldn't find the page you're looking for"}
  end

  error do
    haml :"static/error", :layout => false, :locals => {:code => 500, :message => "Something went wrong"}
  end

end
