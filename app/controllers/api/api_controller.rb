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

    class BadRequest < StandardError; end
    class NotFound < StandardError; end
  end
end
