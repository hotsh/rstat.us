module Api
  class SubscriptionsController < ApiController
    #
    # Disable CSRF protection
    #
    # XXX we're kinda reaching into protect_from_forgery here.
    #
    skip_before_filter :verify_authenticity_token

    doorkeeper_for :destroy, :scopes => [:write]

    rescue_from StandardError, :with => :handle_error

    def create
      user = requested_user!
      current_user.follow! user.feed if user != current_user
      respond_to do |format|
        format.json do
          user  = UserTwitterJsonDecorator.decorate(user)
          render :json => user.as_json
        end
      end
    end

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

    def exists
      params[:user_id] = params[:user_id_a]
      params[:screen_name] = params[:screen_name_a]
      user_a = requested_user!

      params[:user_id] = params[:user_id_b]
      params[:screen_name] = params[:screen_name_b]
      user_b = requested_user!

      render :json => user_a.following_url?(user_b.feed.url).to_json
    end

  end
end

