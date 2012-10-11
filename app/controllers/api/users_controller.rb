module Api
  class UsersController < ApiController

    rescue_from StandardError, :with => :handle_error

    def show
      user = requested_user!
      respond_to do |format|
        format.json do
          user = UserTwitterJsonDecorator.decorate(user)
          render :json => user.as_json
        end
      end
    end

  end
end
