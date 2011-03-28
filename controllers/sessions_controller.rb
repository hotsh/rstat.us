class Rstatus

  get "/login" do
    if logged_in?
      redirect '/'
    else
      haml :"login"
    end
  end

  post "/login" do
    u = User.first :username => params[:username]
    if u.nil?
      #signup
      user = User.new params
      if user.save
        session[:user_id] = user.id
        flash[:notice] = "Thanks for signing up!"
        redirect "/"
      else
        puts "not saved"
        flash[:notice] = "There was a problem... can you pick a different username?"
        redirect "/login"
      end
    else
      #login
      if user = User.authenticate(params[:username], params[:password])
        session[:user_id] = user.id
        flash[:notice] = "Login successful."
        redirect "/"
      else
        flash[:notice] = "The username or password you entered was incorrect"
        redirect "/login"
      end
    end
  end

  get "/logout" do
    if logged_in?
      session[:user_id] = nil
      flash[:notice] = "You've been logged out."
    end
    redirect '/'
  end

end
