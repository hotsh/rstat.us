class FeedsController < ApplicationController

  def show
    respond_to do |format|
      # Since feed url is the URI for the user,
      # redirect to the user's profile page
      # This is also our view for a particular feed
      format.html do
        feed = Feed.first :id => params[:id]
        if feed.local?
          # Redirect to the local profile page
          redirect_to "/users/#{feed.author.username}"
        else
          # Why not...
          # While weird, to render the view for this model, one
          # has to go to another site. This is the new age.
          redirect_to feed.author.remote_url
        end
      end

      format.atom do
        # We do have to provide a rendered feed to the hub, and this controller does
        # it. Publishers will also view a feed in order to verify their subscription.
        feed = Feed.first :id => params[:id]

        # TODO: Abide by headers that supply cache information
        render :text => feed.atom(root_url)
      end
    end
  end
end
