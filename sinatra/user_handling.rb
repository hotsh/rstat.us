# Here's the story: Since Steve totally sucks at writing validations, we have a
# bunch of users with screwed up usernames, so we also have a bunch of stuff
# that handles those cases. In a few weeks we should be able to clean out this
# entire file. Woohoo!

class Rstatus
  # EMPTY USERNAME HANDLING - quick and dirty
  before do
    @error_bar = ""
    if current_user && (current_user.username.nil? or current_user.username.empty? or !current_user.username.match(/profile.php/).nil?)
      @error_bar = haml :"login/_username_error", :layout => false
    end
  end

  # Allows a user to reset their username. Currently only allows users that
  # are not registered, users without a username and facebook users with the
  # screwed up username
  get '/reset-username' do
    unless current_user.nil? || current_user.username.empty? || current_user.username.match(/profile.php/)
      redirect "/"
    end

    haml :"login/reset_username"
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
      haml :"login/reset_username"
    end
  end
end
