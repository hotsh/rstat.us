class Rstatus
  
  # publisher will feed the atom to a hub
  get "/feeds/:id.atom" do
    feed = Feed.first :id => params[:id]

    content_type "application/atom+xml"

    # TODO: Abide by headers that supply cache information
    body feed.atom url("/")
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
