module Api
  class ApiController < ApplicationController

  protected

    def format_errors(errors)
      errors = errors.full_messages.map do |error|
        #
        # TODO we probably want to provide other errors codes here.
        #
        # 34 = "Sorry, that page does not exist"
        # 130 = "Over Capacity"
        # 131 = "Internal Error"
        #
        error_code = 131

        {:message => error, :code => 131}
      end
      {:errors => errors}.to_json
    end
    
    def handle_error(e)
      respond_to do |fmt|
        fmt.json do
          status = {
            NotFound => :not_found,
            BadRequest => :bad_request
          }[e.class]
          raise e if status.nil?
          render :status => status, :json => [e.message].to_json
        end
      end
    end

    def requested_user!
      if params[:user_id].blank? && params[:screen_name].blank?
        #
        # TODO this is an assumption. Verify against Twitter API.
        #
        raise BadRequest, "You must specify either user_id or screen_name"
      elsif !params[:user_id].blank? && !params[:screen_name].blank?
        #
        # TODO verify if/how Twitter deals with this. Edge case, anyway.
        #
        raise BadRequest, "You can't specify both user_id and screen_name"
      end

      #
      # Try to find a user by user_id first, then screen_name
      #
      user = nil
      user = User.find_by_id(params[:user_id]) if !params[:user_id].blank?
      if user.nil?
        if !params[:screen_name].blank?
          user = User.first(:username => params[:screen_name])
          if user.nil?
            raise NotFound, "User does not exist: #{params[:screen_name]}"
          end
        else
          raise NotFound, "User ID does not exist: #{params[:user_id]}"
        end
      end

      user
    end

    class BadRequest < StandardError; end
    class NotFound < StandardError; end
  end
end
