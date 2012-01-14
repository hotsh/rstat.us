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
        render :text => respond[:body], :status => respond[:status]
      else
        # if the verification fails, the specification forces us to
        # return a 404 status
        raise ActionController::RoutingError.new('Not Found')
      end
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  # A DELETE call will unsubscribe you from that particular feed. We make
  # sure that you're logged in first, because otherwise, it's nonsensical.
  def destroy
    require_login! :return => request.referrer

    feed = Feed.first :id => params[:id]

    @author = feed.author

    if @author.user == current_user
      # You're not allowed to follow yourself.
      redirect_to request.referrer
    elsif !current_user.following_url? feed.url
      # If we're not following them, noop.
      flash[:notice] = "You're not following #{@author.username}."
      redirect_to request.referrer
    else
      current_user.unfollow! feed

      flash[:notice] = "No longer following #{@author.username}."
      redirect_to request.referrer
    end
  end

  # subscriber receives updates
  # should be 'put', PuSH sucks at REST
  def post_update
    feed = Feed.first :id => params[:id]
    if feed.nil?
      raise ActionController::RoutingError.new('Not Found')
    end

    feed.update_entries(request.body.read, request.url, feed.url, request.env['HTTP_X_HUB_SIGNATURE'])
    render :nothing => true
  end

  # A POST is how you subscribe to someone's feed. We want to make sure
  # that you're logged in for this one, too.
  def create
    require_login! :return => request.referrer

    # Find or create the Feed
    subscribe_to_feed = Feed.first(:id => params[:subscribe_to])

    unless subscribe_to_feed
      # Allow for a variety of feed addresses
      case params[:subscribe_to]
      when /^feed:\/\//
        # SAFARI!!!!1 /me shakes his first at the sky
        feed_url = "http" + params[:subscribe_to][4..-1]
      when /@/
        # XXX: ensure caching of finger lookup.
        redfinger_lookup = Redfinger.finger(params[:subscribe_to])
        feed_url = redfinger_lookup.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }.to_s
      else
        feed_url = params[:subscribe_to]
      end

      # See if we already have a local feed for this remote
      subscribe_to_feed = Feed.first(:remote_url => feed_url)

      unless subscribe_to_feed
        # create a feed
        subscribe_to_feed = Feed.create(:remote_url => feed_url)
        # Populate the Feed with Updates and Author from the remote site
        # Pass along the redfinger information to build the Author if available
        subscribe_to_feed.populate redfinger_lookup
      end
    end

    # Stop and return a nice message if already following this feed
    if current_user.following_feed? subscribe_to_feed
      flash[:notice] = "You're already following #{subscribe_to_feed.author.username}."
      redirect_to request.referrer
    end

    # Actually follow!
    f = current_user.follow! subscribe_to_feed

    unless f
      flash[:notice] = "There was a problem following #{params[:subscribe_to_feed]}."
      redirect_to request.referrer
    end

    # Attempt to inform the hub for remote feeds
    unless f.local? || f.hubs.empty?
      hub_url = f.hubs.first

      sub = OSub::Subscription.new(subscription_url(f.id, :format => "atom"), f.url, f.secret)
      sub.subscribe(hub_url, true, f.verify_token)
    end

    flash[:notice] = "Now following #{f.author.username}."
    redirect_to request.referrer
  end
end
