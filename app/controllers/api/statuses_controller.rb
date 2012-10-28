module Api
  class StatusesController < ApiController
    #
    # Disable CSRF protection
    #
    # XXX we're kinda reaching into protect_from_forgery here.
    #
    skip_before_filter :verify_authenticity_token

    doorkeeper_for :home_timeline, :mention, :scopes => [:read]
    doorkeeper_for :update, :destroy, :scopes => [:write]

    rescue_from StandardError, :with => :handle_error

    def show
      update = Update.find(params[:id])
      if !update.nil?
        respond_to do |format|
          format.json do
            include_entities = (params[:include_entities] == "true")
            trim_user = (params[:trim_user] == "true")
            update = UpdateTwitterJsonDecorator.decorate(update)
            render :json => update.as_json(:include_entities => include_entities,:trim_user => trim_user)
          end
        end
      else
        render :nothing => true, :status => 404
      end
    end

    def update
      update = current_user.feed.add_update(update_options)

      if update.valid?
        current_user.feed.save
        current_user.save
        current_user.feed.ping_hubs

        respond_to do |fmt|
          fmt.json do
            include_entities = (params[:include_entities] == "true")
            trim_user = (params[:trim_user] == "true")
            update = UpdateTwitterJsonDecorator.decorate(update)
            render :json => update.as_json(:include_entities => include_entities,
                                      :trim_user => trim_user)
          end
        end
      else
        respond_to do |fmt|
          fmt.json {
            render :status => :bad_request,
                   :json   => format_errors(update.errors)
          }
        end
      end
    end

    def home_timeline
      timeline_for current_user
    rescue => e
      handle_error e
    end

    def user_timeline
      timeline_for requested_user!
    rescue => e
      handle_error e
    end

    def mention
      options = timeline_options
      updates = current_user.at_replies(options)
      respond_to do |fmt|
        fmt.json do
          json = updates.map do |update|
            update = UpdateTwitterJsonDecorator.decorate(update)
            update.as_json(:include_entities => options[:include_entities],
                           :trim_user => options[:trim_user])
          end
          render :json => json
        end
      end
    end

    def destroy
      update = Update.find_by_id(params[:id])
      if update.nil?
        raise NotFound, "Status ID does not exist: #{params[:id]}"
      end
      if update.author != current_user.author
        raise BadRequest, "I'm afraid I can't let you do that, #{current_user.username}."
      end
      update.destroy

      respond_to do |fmt|
        fmt.json do
          include_entities = (params[:include_entities] == "true")
          trim_user = (params[:trim_user] == "true")
          update = UpdateTwitterJsonDecorator.decorate(update)
          render :json => update.as_json(:include_entities => include_entities,
                                    :trim_user => trim_user)
        end
      end
    end

    protected

    def timeline_for(user)
      options = timeline_options
      updates = user.timeline(options)
      respond_to do |fmt|
        fmt.json do
          json = updates.map do |update|
            update = UpdateTwitterJsonDecorator.decorate(update)
            update.as_json(:include_entities => options[:include_entities],
                           :trim_user => options[:trim_user])
          end
          render :json => json
        end
      end
    end

    def timeline_options
      options = {}
      attrs = [
        [:count,               :int],
        [:since_id,            :str],
        [:max_id,              :str],
        [:page,                :int],  # TODO (deprecated)
        [:trim_user,           :bool],
        [:include_rts,         :bool], # XXX ???
        [:include_entities,    :bool],
        [:exclude_replies,     :bool], # TODO not sure of the semantics...
        [:contributor_details, :bool]  # TODO not sure of the semantics...
      ]
      attrs.each do |attr, type|
        case type
        when :int
          options[attr] = params[attr].to_i if !params[attr].nil?
        when :str
          options[attr] = params[attr] if !params[attr].nil?
        when :bool
          options[attr] = (params[attr] == "true") if !params[attr].nil?
        else
          raise BadRequest, "unknown attribute type: #{type}"
        end
      end
      options
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
