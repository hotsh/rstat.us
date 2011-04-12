class Rstatus

  # We do have to provide a rendered feed to the hub, and this controller does
  # it. Publishers will also view a feed in order to verify their subscription.
  get "/feeds/:id.atom" do
    content_type "application/atom+xml"

    feed = Feed.first :id => params[:id]

    # XXX: wilkie needs to handle this.
    # I'm baleeting his commented out code, because that's what `git` is for.
    if params['hub.challenge']
      status 404
    else
      # XXX: Abide by headers that supply cache information
      body feed.atom(uri("/"))
    end
  end

end
