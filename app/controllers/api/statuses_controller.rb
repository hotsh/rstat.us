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
    # POST /api/statuses/update.json
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

    protected

    def handle_error(e)
      respond_to do |fmt|
        fmt.json do
          status = {
            NotFound => :not_found,
            BadRequest => :bad_request
          }[e.class]
          raise e if status.nil?
          render :status => status, :json => [e.message]
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
      user = User.first(params[:user_id]) if !params[:user_id].blank?
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

    class BadRequest < StandardError; end
    class NotFound < StandardError; end
  end
end

