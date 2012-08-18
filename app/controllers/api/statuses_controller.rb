module Api
  class StatusesController < ApplicationController
    #
    # Disable CSRF protection
    #
    # XXX we're kinda reaching into protect_from_forgery here.
    #
    skip_before_filter :verify_authenticity_token

    #
    # TODO replace with OAuth goodness.
    #
    before_filter :require_user

    #
    # POST /api/1/statuses/update.json
    #
    def update
      u = current_user.feed.add_update(update_options)

      if u.valid?
        current_user.feed.save
        current_user.save
        current_user.feed.ping_hubs

        respond_to do |fmt|
          fmt.json do
            include_entities = (params[:include_entities] == "true")
            trim_user = (params[:trim_user] == "true")
            u = UpdateTwitterJsonDecorator.decorate(u)
            render :json => u.as_json(:include_entities => include_entities,
                                      :trim_user => trim_user)
          end
        end
      else
        respond_to do |fmt|
          fmt.json { render :status => :bad_request, :json => format_errors(u.errors) }
        end
      end
    end

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

    def update_options
      {
        :text => params[:status],
        :referral_id => params[:in_reply_to_status_id],
        :author => current_user.author,

        # rstat.us extensions
        :twitter => (params[:tweet] == "true")
      }
    end
  end
end

