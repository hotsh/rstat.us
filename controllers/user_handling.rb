class Rstatus
  # EMPTY USERNAME HANDLING - quick and dirty
  before do
    @error_bar = ""
    if current_user && (current_user.username.nil? or current_user.username.empty? or !current_user.username.match(/profile.php/).nil?)
      @error_bar = haml :_username_error, :layout => false
    end
  end

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
  
  get '/forgot_password' do
    haml :"forgot_password"
  end
  
  post '/forgot_password' do
    user = User.where(:email => params[:email])
    
  end
  
  get '/password_reset/:token' do
    user = User.where(:perishable_token => params[:token])
    if user.nil? || user.password_reset_sent > 2.days.ago
      params[:notice] == "Your link is no longer valid, please request another one."
      haml :"forgot_password"
    else
      @token = params[:token]
      haml :"password_reset"
    end
  end
  
  post '/password_reset' do
    if params[:token]
      if params[:password].size == 0
        params[:notice] == "Password must be present"
        redirect "/password_reset/#{params[:token]}"
      end
      if params[:password] != params[:password_confirm]
        params[:notice] == "Passwords do not match"
        redirect "/password_reset/#{params[:token]}"
      end
      user = User.where(:perishable_token => params[:token])
      user.password = params[:password]
      user.reset_password(params[:password])
      params[:notice] == "Password successfully set"
      redirect "/"
    else
      redirect "/forgot_password"
    end
  end
  
  get '/users/password_reset' do
    if logged_in?
      haml :"user/password_reset"
    else
      redirect "/forgot_password"
    end
  end
end
