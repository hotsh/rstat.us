class SubscriptionsController < ApplicationController
  before_filter :find_feed, :except => :create

  def show
    if params['hub.challenge']
      sub = OSub::Subscription.new(request.url, @feed.url, nil, @feed.verify_token)

      # perform the hub's challenge
      respond = sub.perform_challenge(params['hub.challenge'])

      # verify that the random token is the same as when we
      # subscribed with the hub initially and that the topic
      # url matches what we expect
      verified = params['hub.topic'] == @feed.url
      if verified && sub.verify_subscription(params['hub.verify_token'])
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
    require_login! :return => request.referrer and return

    @author = @feed.author

    if @author.user == current_user
      # You're not allowed to follow yourself.
      redirect_to request.referrer
    elsif !current_user.following_url? @feed.url
      # If we're not following them, noop.
      flash[:notice] = "You're not following #{@author.username}."
      redirect_to request.referrer
    else
      current_user.unfollow! @feed

      flash[:notice] = "No longer following #{@author.username}."
      redirect_to request.referrer
    end
  end

  # subscriber receives updates
  # should be 'put', PuSH sucks at REST
  def post_update
    raise ActionController::RoutingError.new('Not Found') if @feed.nil?

    @feed.update_entries(request.body.read, request.url, @feed.url, request.env['HTTP_X_HUB_SIGNATURE'])
    render :nothing => true
  end

  # A POST is how you subscribe to someone's feed. We want to make sure
  # that you're logged in for this one, too.
  def create
    require_login! :return => request.referrer and return

    # Find or create the Feed
    begin
      subscribe_to_feed = Feed.find_or_create(params[:subscribe_to])
    rescue RstatUs::InvalidSubscribeTo => e
      # This means the user's entry was neither a webfinger identifier
      # nor a feed URL, and calling `open` on it did not return anything.
      flash[:error] = "There was a problem following #{params[:subscribe_to]}. Please specify the whole ID for the person you would like to follow, including both their username and the domain of the site they're on. It should look like an email address-- for example, username@status.net"
      redirect_to request.referrer
      return
    end

    # Stop and return a nice message if already following this feed
    if current_user.following_feed? subscribe_to_feed
      flash[:notice] = "You're already following #{subscribe_to_feed.author.username}."
      redirect_to request.referrer
      return
    end

    # Actually follow!
    f = current_user.follow! subscribe_to_feed

    unless f
      flash[:error] = "There was a problem following #{params[:subscribe_to]}."
      redirect_to request.referrer
      return
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

  private

  def find_feed
    @feed = Feed.first :id => params[:id]
  end
end
