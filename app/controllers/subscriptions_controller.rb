class SubscriptionsController < ApplicationController
  def show

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
          p respond
        end
        body respond[:body]
        status respond[:status]
      else
        if development?
          puts "Verification Failed"
          p respond
        end
        # if the verification fails, the specification forces us to
        # return a 404 status
        status 404
      end
    else
      status 404
    end
  end

  # A DELETE call will unsubscribe you from that particular feed. We make
  # sure that you're logged in first, because otherwise, it's nonsensical.
  def destroy
    require_login! :return => request.referrer

    feed = Feed.first :id => params[:id]

    @author = feed.author

    # You're not allowed to follow yourself.
    redirect_to request.referrer if @author.user == current_user

    # If we're already following them, noop.
    unless current_user.following_url? feed.url
      flash[:notice] = "You're not following #{@author.username}."
      redirect_to request.referrer
    end

    current_user.unfollow! feed

    flash[:notice] = "No longer following #{@author.username}."
    redirect_to request.referrer
  end

  # subscriber receives updates
  # should be 'put', PuSH sucks at REST
  def post_update
    feed = Feed.first :id => params[:id]
    if feed.nil?
      status 404
      return
    end
    if development?
      puts "Hub post received for #{feed.author.username}."
    end
    feed.update_entries(request.body.read, request.url, feed.url, request.env['HTTP_X_HUB_SIGNATURE'])
  end

  # A POST is how you subscribe to someone's feed. We want to make sure
  # that you're logged in for this one, too.
  def create
    require_login! :return => request.referrer

    feed_url = nil

    # We need to also pass along the Redfinger look up to follow!
    # if it is retrieved for a remote user:
    acct = nil

    # Allow for a variety of feed addresses
    case params[:url]
    when /^feed:\/\//
      # SAFARI!!!!1 /me shakes his first at the sky
      feed_url = "http" + params[:url][4..-1]
    when /@/
      # XXX: ensure caching of finger lookup.
      acct = Redfinger.finger(params[:url])
      feed_url = acct.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }.to_s
    else
      feed_url = params[:url]

      # Determine if it is a remote feed that is locally addressed
      # If it is, then let's get the remote url and use that instead
      if feed_url.start_with?("/")
        feed_id = feed_url[/^\/feeds\/(.+)$/,1]
        feed = Feed.first(:id => feed_id)

        if not feed.nil? and not feed.remote_url.nil?
          # This is a remote feed that we already know about
          feed_url = feed.remote_url
        end
      end
    end

    # If we're already following them, noop
    if current_user.following_url? feed_url
      feed = Feed.first(:remote_url => feed_url)
      if feed.nil? and feed_url.start_with?("/")
        feed_id = feed_url[/^\/feeds\/(.+)$/,1]
        feed = Feed.first(:id => feed_id)
        if feed.nil?
          status 404
          return
        end
      end

      flash[:notice] = "You're already following #{feed.author.username}."

      redirect_to request.referrer
    end

    f = current_user.follow! feed_url, acct

    unless f
      flash[:notice] = "There was a problem following #{params[:url]}."
      redirect_to request.referrer
    end

    if not f.local?
      # Remote feeds require some talking to a hub.
      if not f.hubs.empty?
        hub_url = f.hubs.first

        sub = OSub::Subscription.new(subscription_url(f.id, :format => "atom"), f.url, f.secret)
        sub.subscribe(hub_url, false, f.verify_token)
      end

      name = f.author.username

      flash[:notice] = "Now following #{name}."
      redirect_to request.referrer
    else
      # If it's a local feed, then we're already good.
      flash[:notice] = "Now following #{f.author.username}."
      redirect_to request.referrer
    end
  end
end
