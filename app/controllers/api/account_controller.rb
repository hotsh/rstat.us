module Api
  class AccountController < ApiController
    #
    # Disable CSRF protection
    #
    # XXX we're kinda reaching into protect_from_forgery here.
    #
    skip_before_filter :verify_authenticity_token

    doorkeeper_for :verify_credentials

    rescue_from StandardError, :with => :handle_error

    def verify_credentials
      respond_to do |format|
        format.json do
          user = UserTwitterJsonDecorator.decorate(current_user)
          render :json => user.to_json(
                            :include_status => true,
                            :root_url => root_url
                          )
        end
      end
    end
  end
end