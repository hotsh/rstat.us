module Api
  class SubscriptionsController < ApiController 
    #
    # Disable CSRF protection
    #
    # XXX we're kinda reaching into protect_from_forgery here.
    #
    skip_before_filter :verify_authenticity_token

    #
    # TODO replace with OAuth goodness.
    #
    #

    before_filter :require_user

    rescue_from StandardError, :with => :handle_error

    def destroy
      user = requested_user!
      if user == current_user
        raise BadRequest, "Can't unfollow yourself"
      elsif !current_user.following_url? user.feed.url
        raise BadRequest, "You are not following this user"
      else
        current_user.unfollow! user.feed
        respond_to do |format|
          format.json do
            user  = UserTwitterJsonDecorator.decorate(user)
            render :json => user.as_json
          end
        end
      end
    end

  end
end

