class Rstatus
  # EMPTY USERNAME HANDLING - quick and dirty
  before do
    @error_bar = ""
    if current_user && (current_user.username.nil? or current_user.username.empty? or !current_user.username.match(/profile.php/).nil?)
      @error_bar = haml :_username_error, :layout => false
    end
  end
  
  # Allows a user to reset their username. Currently only allows users that
  # are not registered, users without a username and facebook users with the
  # screwed up username
  get '/reset-username' do
    unless current_user.nil? || current_user.username.empty? || current_user.username.match(/profile.php/)
      redirect "/"
    end

    haml :reset_username
  end

  post '/reset-username' do
    exists = User.first :username => params[:username]
    if !params[:username].nil? && !params[:username].empty? && exists.nil?
      if current_user.reset_username(params)
        flash[:notice] = "Thank you for updating your username"
      else
        flash[:notice] = "Your username could not be updated"
      end
      redirect "/"
    else
      flash[:notice] = "Sorry, that username has already been taken or is not valid. Please try again."
      haml :reset_username
    end
  end
  
  # Passwords can be reset by unauthenticated users by navigating to the forgot
  # password and page and submitting the email address they provided.
  get '/forgot_password' do
    haml :"forgot_password"
  end
  
  # The email address is looked up, if no user is found an error is provided. If
  # a user is found a token is generated and an email is sent to the user with a
  # url to reset their password. Users are then redirected to the confirmation
  # page to prevent repost issues
  post '/forgot_password' do
    user = User.first(:email => params[:email])
    if user.nil?
      flash[:notice] = "Your account could not be found, please check your email and try again."
      haml :"forgot_password"
    else
      Notifier.send_forgot_password_notification(user.email, user.set_password_reset_token)
      # Redirect to try to avoid repost issues
      session[:fp_email] = user.email
      redirect '/forgot_password_confirm'
    end
  end
  
  # Forgot password confirmation screen, displays email address that the email
  # was sent to
  get '/forgot_password_confirm' do
    @email = session.delete(:fp_email)
    haml :"forgot_password_confirm"
  end
  
  # Public reset password page, accessible via a valid token. Tokens are only
  # valid for 2 days and are unique to that user. The user is found using the
  # token and the reset password page is rendered
  get '/reset_password/:token' do
    user = User.first(:perishable_token => params[:token])
    if user.nil? || user.password_reset_sent.to_time < 2.days.ago
      flash[:notice] = "Your link is no longer valid, please request a new one."
      redirect "/forgot_password"
    else
      @token = params[:token]
      haml :"reset_password"
    end
  end
  
  # The reset token is sent on the url along with the post to ensure
  # authentication is preserved. The password is checked for length and
  # confirmation and the token is rechecked for authenticity. If all checks pass
  # the user's password is reset, the token removed from the user model, a
  # session created for the user and they are redirected to /
  post '/reset_password/:token' do
    if params[:token]
      # Repeated in users_controller /users/password_reset, make sure any
      # changes are in sync
      if params[:password].size == 0
        flash[:notice] = "Password must be present"
        redirect "/reset_password/#{params[:token]}"
      end
      if params[:password] != params[:password_confirm]
        flash[:notice] = "Passwords do not match"
        redirect "/reset_password/#{params[:token]}"
      end
      # end 
      user = User.first(:perishable_token => params[:token])
      if user.nil? || user.password_reset_sent.to_time < 2.days.ago
        flash[:notice] = "Your link is no longer valid, please request another one."
        redirect "/forgot_password"
      else
        user.reset_password(params[:password])
        # Register a session for the user
        session[:user_id] = user.id
        flash[:notice] = "Password successfully set"
        redirect "/"
      end
    else
      redirect "/forgot_password"
    end
  end
end
