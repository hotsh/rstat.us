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
      if params[:user_id]
        @user = User.find_by_id params[:user_id]
      elsif params[:screen_name]
        @user = User.find_by_username params[:screen_name]
      else
        raise BadRequest, "You must supply a user_id or a screen_name"
      end

      raise BadRequest, "User not found" if @user.nil?
      feed = @user.feed
      if @user == current_user
        raise BadRequest, "Can't unfollow yourself"
      elsif !current_user.following_url? feed.url
        raise BadRequest, "You are not following this user"
      else
        current_user.unfollow! feed
        respond_to do |format|
          format.json do
            user  = UserTwitterJsonDecorator.decorate(@user)
            render :json => user.as_json
          end
        end
      end
    end

  end
end

