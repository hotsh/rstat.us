class Rstatus
  # Omniauth callback after a successful oauth session has been established.
  # New users and existing users adding linked accounts both use this callback
  # to obtain oauth credentials. 
  # If an authorization is not present then that request is assumed to be for a
  # new account. If a request comes from a user that is logged in, it is assumed
  # to originate from the edit profile page and the request is to add a linked
  # account. If the request does not come from a user it is assumed to be a new
  # user and the auth information is collected to provision a new account. The
  # username is checked to ensure it is unique, if it is not, or if there is a
  # screwy facebook nickname the user is redirected to /users/new to change
  # their registration information. If the username is unique and not facebook
  # screwery the user is sent to the confirmation page where they will confirm
  # their username and enter an email address.
  # If an authorization is present then it is assumed to be a successful
  # authentication. The oauth credentials for the user in question are checked
  # and stored if not present (this is to provide oauth credentials for legacy
  # users). A new user session is generated and the user is redirected to /
  get '/auth/:provider/callback' do
    auth = request.env['omniauth.auth']
    unless @auth = Authorization.find_from_hash(auth)
      if logged_in?
        # A logged in user means that this request originated from the edit
        # profile page and they are trying to add a linked account.
        Authorization.create_from_hash(auth, uri("/"), current_user)
        redirect "/users/#{current_user.username}/edit"
      else
        session[:uid] = auth['uid']
        session[:provider] = auth['provider']
        session[:name] = auth['user_info']['name']
        session[:nickname] = auth['user_info']['nickname']
        session[:website] = auth['user_info']['urls']['Website']
        session[:description] = auth['user_info']['description']
        session[:image] = auth['user_info']['image']
        session[:email] = auth['user_info']['email']
        #let's store their oauth stuff so they don't have to re-login after
        session[:oauth_token] = auth['credentials']['token']
        session[:oauth_secret] = auth['credentials']['secret']

        # We can probably get rid of this since the user confirmation will
        # check for duplicate usernames [brimil01]
        if User.first :username => auth['user_info']['nickname'] or auth['user_info']['nickname'] =~ /profile[.]php[?]id=/
          #we have a username conflict!
          flash[:notice] = "Sorry, someone has that name."
          redirect '/users/new'
          return
        else
          # Redirect to confirm page to verify username and provide email
          redirect '/users/confirm'
          return
        end
      end
    end

    ## Lets store the tokens if they don't alreay exist
    if @auth.oauth_token.nil?
      @auth.oauth_token = auth['credentials']['token']
      @auth.oauth_secret = auth['credentials']['secret']
      @auth.nickname = auth['user_info']['nickname']
      @auth.save
    end

    session[:user_id] = @auth.user.id

    flash[:notice] = "You're now logged in."
    redirect '/'
  end

  get '/auth/failure' do
    if params[:message] == "invalid_credentials"
      haml :"signup/invalid_credentials"
    else
      raise Sinatra::NotFound
    end
  end
end
