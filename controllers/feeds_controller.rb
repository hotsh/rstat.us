class Rstatus
  
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

end
