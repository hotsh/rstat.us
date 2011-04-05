class Rstatus
  
  # subscribers will verify a subscription
  get "/subscriptions/:id.atom" do
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
  post "/subscriptions/:id.atom" do
    feed = Feed.first :id => params[:id]
    if feed.nil?
      status 404
      return
    end
    if development?
      puts "Hub post received for #{feed.author.username}."
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

      sub = OSub::Subscription.new(url("/subscriptions/#{f.id}.atom"), f.url, f.secret)
      sub.subscribe(hub_url, false, f.verify_token)

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
