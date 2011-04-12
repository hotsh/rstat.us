# Even though a 'subscription' isn't an actual model, we still treat it as a
# resource for maximum RESTful-ness. After all, it could be one, but we just
# don't need to keep any data about the subscription itself.

class Rstatus

  # A DELETE call will unsubscribe you from that particular feed. We make
  # sure that you're logged in first, because otherwise, it's nonsensical.
  delete '/subscriptions/:id' do
    require_login! :return => request.referrer

    feed = Feed.first :id => params[:id]

    @author = feed.author

    # You're not allowed to follow yourself.
    redirect request.referrer if @author.user == current_user

    # If we're already following them, noop.
    unless current_user.following? feed.url
      flash[:notice] = "You're not following #{@author.username}."
      redirect request.referrer
    end

    current_user.unfollow! feed

    flash[:notice] = "No longer following #{@author.username}."
    redirect request.referrer
  end

  # A POST is how you subscribe to someone's feed. We want to make sure 
  # that you're logged in for this one, too.
  post "/subscriptions" do
    require_login! :return => request.referrer

    feed_url = nil

    # Allow for a variety of feed addresses
    case params[:url]
    when /^feed:\/\//
      # SAFARI!!!!1 /me shakes his first at the sky
      feed_url = "http" + params[:url][4..-1]
    when /@/
      # XXX: ensure caching of finger lookup.
      acct = Redfinger.finger(params[:url])
      feed_url = acct.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }
    else
      feed_url = params[:url]
    end

    # If we're already following them, noop
    if current_user.following? feed_url
      feed = Feed.first(:remote_url => feed_url)
      if feed.nil? and feed_url[0] == "/"
        feed_id = feed_url[/^\/feeds\/(.+)$/,1]
        feed = Feed.first(:id => feed_id)
      end

      flash[:notice] = "You're already following #{feed.author.username}."

      redirect request.referrer
    end

    f = current_user.follow! feed_url

    unless f
      flash[:notice] = "There was a problem following #{params[:url]}."
      redirect request.referrer
    end

    if not f.local?
      # Remote feeds require some talking to a hub. Yay for the ostatus gem!
      hub_url = f.hubs.first

      sub = OSub::Subscription.new(url("/feeds/#{f.id}.atom"), f.url, f.secret)
      sub.subscribe(hub_url, f.verify_token)

      name = f.author.username
      flash[:notice] = "Now following #{name}."
      redirect request.referrer
    else
      # If it's a local feed, then we're already good.
      flash[:notice] = "Now following #{f.author.username}."
      redirect request.referrer
    end
  end

end
