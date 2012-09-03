# This controller handles all of the external authentication needs of Rstatus.
# We're using OmniAuth to handle our Twitter connections, so these
# routes are all derived from that codebase.
class AuthController < ApplicationController
  before_filter :require_user, :only => :destroy

  # Omniauth callback after a successful oauth session has been established.
  # New users and existing users adding linked accounts both use this callback
  # to obtain oauth credentials.
  def auth
    auth = request.env['omniauth.auth']

    # If an authorization is not present then that request is assumed to be for
    # a new account. If a request comes from a user that is logged in, it is
    # assumed to originate from the edit profile page and the request is to add
    # a linked account. If the request does not come from a user it is assumed
    # to be a new user and the auth information is collected to provision a new
    # account.
    unless @auth = Authorization.find_from_hash(auth)
      if logged_in?
        Authorization.create_from_hash!(auth, root_url, current_user)
        redirect_to edit_user_path(current_user)
        return
      else

        # This situation here really sucks. I'd like to do something better,
        # and maybe the correct answer is just session[:auth] = auth. This
        # might be a nice refactoring.
        session[:uid] = auth['uid']
        session[:provider] = auth['provider']
        session[:name] = auth['info']['name']
        session[:nickname] = auth['info']['nickname']
        session[:website] = auth['info']['urls']['Website']
        session[:description] = auth['info']['description']
        session[:image] = auth['info']['image']
        session[:email] = auth['info']['email']
        session[:oauth_token] = auth['credentials']['token']
        session[:oauth_secret] = auth['credentials']['secret']

        # The username is checked to ensure it is unique, if it is not,
        # the user is informed that they need to change it.
        # Everyone is redirected to /users/new to confirm that they'd like
        # to have their username.
        if User.first :username => auth['info']['nickname']
          flash[:error] = "Sorry, someone else has that username. Please pick another."
        end

        redirect_to new_user_path
        return
      end
    end

    # If an authorization is present then it is assumed to be a successful
    # authentication. The oauth credentials for the user in question are checked
    # and updated.

    @auth.oauth_token = auth['credentials']['token']
    @auth.oauth_secret = auth['credentials']['secret']
    @auth.nickname = auth['info']['nickname']
    @auth.save

    sign_in(@auth.user)

    flash[:notice] = "You're now logged in."

    redirect_to root_path
  end

  def invalid_auth_provider
    flash[:error] = "We were unable to use your credentials because we do not support logging in with #{params[:provider]}."
    redirect_to new_session_url
  end

  def failure
    if params[:message] == "invalid_credentials"
      flash[:error] = "We were unable to use your credentials to log you in. " +
                      "Try again?"
    elsif params[:message] == "timeout"
      flash[:error] = "We were unable to use your credentials because of a timeout. " +
                      "This is likely a temporary problem so feel free to try again."
    else
      flash[:error] = "We were unable to use your credentials because of a yet " +
                      "undetermined problem. Hopefully this is temporary so " +
                      "feel free to try again."
    end

    redirect_to new_session_url
  end

  # This lets someone remove a particular Authorization from their account.
  def destroy
    auth = current_user.authorizations.where(:provider => params[:provider])
    auth.map(&:destroy) unless auth.empty?
    # Without re-setting the session[:user_id] we're logged out
    sign_in(current_user)

    redirect_to edit_user_path(current_user)
  end
end
