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
end
