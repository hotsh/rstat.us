class FeedsController < ApplicationController

  def show
    feed = Feed.first :id => params[:id]

    unless feed
      render :file => "#{Rails.root}/public/404", :status => 404
      return
    end

    respond_to do |format|
      # Since feed url is the URI for the user,
      # redirect to the user's profile page
      # This is also our view for a particular feed
      format.html do
        if feed.local?
          # Redirect to the local profile page
          redirect_to user_path(feed.author)
        else
          # Why not...
          # While weird, to render the view for this model, one
          # has to go to another site. This is the new age.
          redirect_to feed.author.remote_url
        end
      end

      format.atom do
        # We do have to provide a rendered feed to the hub, and this controller
        # does it. Publishers will also view a feed in order to verify their
        # subscription.

        # TODO: Abide by headers that supply cache information
        render :text => feed.atom(root_url, :since => request.if_modified_since)
      end
    end
  end
end
