class Rstatus
  
  # publisher will feed the atom to a hub
  # subscribers will verify a subscription
  get "/feeds/:id.atom" do
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
        end
        # if the verification fails, the specification forces us to
        # return a 404 status
        status 404
      end
    else
      content_type "application/atom+xml"

      # TODO: Abide by headers that supply cache information
      @feed = feed
      @base_url = url("/")
      @hostname = request.host

      body feed.atom url("/")
    end
  end

  # Since feed url is the URI for the user,
  # redirect to the user's profile page
  # This is also our view for a particular feed
  get "/feeds/:id" do
    feed = Feed.first :id => params[:id]
    if feed.local?
      # Redirect to the local profile page
      redirect "/users/#{feed.author.username}"
    else
      # Why not...
      # While weird, to render the view for this model, one
      # has to go to another site. This is the new age.
      redirect feed.author.remote_url
    end
  end

end
