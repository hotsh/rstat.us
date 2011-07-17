module Sinatra
  module UserHelper

    # This incredibly useful helper gives us the currently logged in user. We
    # keep track of that by just setting a session variable with their id. If it
    # doesn't exist, we just want to return nil.
    def current_user
      return unless session[:user_id]
      @current_user ||= User.first(:id => session[:user_id])
    end

    # This very simple method checks if we've got a logged in user. That's pretty
    # easy: just check our current_user.
    def logged_in?
      current_user
    end

    # Our `admin_only!` helper will only let admin users visit the page. If
    # they're not an admin, we redirect them to either / or the page that we
    # specified when we called it.
    def admin_only!(opts = {:return => "/"})
      unless logged_in? && current_user.admin?
        flash[:error] = "Sorry, buddy"
        redirect opts[:return]
      end
    end

    # Similar to `admin_only!`, `require_login!` only lets logged in users access
    # a particular page, and redirects them if they're not.
    def require_login!(opts = {:return => "/"})
      unless logged_in?
        flash[:error] = "Sorry, buddy"
        redirect opts[:return]
      end
    end

    # Many pages on rstatus are paginated. To keep track of it in all the
    # different routes we have this handy helper that either picks up
    # the previous setting or resets it to a default value.
    def set_params_page
      params[:page] = params.fetch("page"){1}.to_i
      params[:per_page] = params.fetch("per_page"){20}.to_i
    end

    # Similar to the set_params_page helper this one creates the links
    # for the previous and the next page on all routes that display
    # stuff on more than one page.
    #If needed it can also take options for more parameters
    def set_pagination_buttons(data, options = {})
      return if data.nil? || data.empty?

      if data.next_page
        params = {
                   :page     => data.next_page,
                   :per_page => data.per_page
                 }.merge(options)

        @next_page = "?#{Rack::Utils.build_query params}"
      end

      if data.previous_page
        params = {
                   :page     => data.previous_page,
                   :per_page => data.per_page
                 }.merge(options)

        @prev_page = "?#{Rack::Utils.build_query params}"
      end
    end
  end

  module ViewHelper
    def pluralize(count, singular, plural = nil)
      "#{count || 0} " + ((count == 1 || count =~ /^1(\.0+)?$/) ? singular : (plural || singular.pluralize))
    end

    def title(str)
      @title = str
      pjax_request? ? @title : nil
    end

    def pjax_request?
      env['HTTP_X_PJAX']
    end

    def show_layout?
      !pjax_request?
    end

    def menu_item(name, url, options = {})
      icon = options.fetch(:icon){ false }
      classes = options.fetch(:classes){ [] }
      
      classes << name.downcase.gsub(" ", "_")
      classes << (request.path_info == url ? "active" : "")  
    
      "<li class='#{classes.join(" ")}'>
        <a href='#{url}'>" +
        (icon ? "<div class='icon'></div>" : "") + 
        "#{name}</a>
      </li>"
    end

  end

  helpers UserHelper
  helpers ViewHelper
end

