class Rstatus

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

  # subscriber receives updates
  # should be 'put', PuSH sucks at REST
  post "/subscribers/:id.atom" do
    feed = Feed.first :id => params[:id]
    if feed.nil?
      status 404
      return
    end
    feed.update_entries(request.body.read, request.url, url(feed.url), request.env['HTTP_X_HUB_SIGNATURE'])
  end

  # Will subscribe the current user to a particular feed
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

end
