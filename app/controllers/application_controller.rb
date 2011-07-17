class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user, :logged_in?, :admin_only!, :menu_item

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
