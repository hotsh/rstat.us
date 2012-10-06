class ApplicationController < ActionController::Base
  protect_from_forgery

  # layout :detect_browser

  helper_method :current_user
  helper_method :logged_in?
  helper_method :admin_only!
  helper_method :require_user
  helper_method :set_params_page
  helper_method :show_layout?
  helper_method :pjax_request?
  helper_method :title
  helper_method :set_pagination_buttons

  protected

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
    redirect_with_sorry(opts) unless logged_in? && current_user.admin?
  end

  # Similar to `admin_only!`, `require_login!` only lets logged in users access
  # a particular page, and redirects them if they're not.
  def require_login!(opts = {:return => "/"})
    redirect_with_sorry(opts) unless logged_in?
  end

  def require_user
    redirect_to root_path unless current_user
  end

  # Many pages on rstatus are paginated. To keep track of it in all the
  # different routes we have this handy helper that either picks up
  # the previous setting or resets it to a default value.
  def set_params_page
    params[:page]     = params.fetch("page"){1}.to_i
    params[:per_page] = params.fetch("per_page"){20}.to_i
  end

  # Similar to the set_params_page helper this one creates the links
  # for the previous and the next page on all routes that display
  # stuff on more than one page.
  # If needed it can also take options for more parameters
  def set_pagination_buttons(data, options = {})
    return if data.blank?

    %w[next previous].each do |type|
      if data.send("#{type}_page")
        params = {
          :page     => data.send("#{type}_page"),
          :per_page => data.per_page
        }.merge(options)

        instance_variable_set(:"@#{type}_page", "?#{Rack::Utils.build_query params}")
      end
    end
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

  def sign_in(user)
    session[:user_id] = user.id
  end

  def sign_out
    session[:user_id] = nil
    @current_user = nil
  end

private

  MOBILE_BROWSERS = ["android", "ipod", "opera mini", "blackberry", "palm","hiptop","avantgo","plucker", "xiino","blazer","elaine", "windows ce; ppc;", "windows ce; smartphone;","windows ce; iemobile", "up.browser","up.link","mmp","symbian","smartphone", "midp","wap","vodafone","o2","pocket","kindle", "mobile","pda","psp","treo"]

  def detect_browser
    agent = request.headers["HTTP_USER_AGENT"].downcase
    if MOBILE_BROWSERS.find { |m| agent.match(m) }
      'mobile'
    else
      'application'
    end
  end

  def redirect_with_sorry(opts)
    flash[:error] = "Sorry, buddy"
    redirect_to opts[:return]
  end

end
