class Rstatus
  get '/users/confirm' do
    haml :"users/confirm"
  end

  get '/users/new' do
    haml :"users/new"
  end
  
  # Password reset for users that are currently logged in. If a user does not
  # have an email address they are prompted to enter one
  get '/users/password_reset' do
    if logged_in?
      haml :"users/password_reset"
    else
      redirect "/forgot_password"
    end
  end

  
  # Submitted passwords are checked for length and confirmation. If the user
  # does not have an email address they are required to provide one. Once the
  # password has been reset the user is redirected to /
  post '/users/password_reset' do
    if logged_in?
      # Repeated in user_handler /reset_password/:token, make sure any changes
      # are in sync
      if params[:password].size == 0
        flash[:notice] = "Password must be present"
        redirect "/users/password_reset"
        return
      end
      if params[:password] != params[:password_confirm]
        flash[:notice] = "Passwords do not match"
        redirect "/users/password_reset"
        return
      end
      
      if current_user.email.nil? 
        if params[:email].empty?
          flash[:notice] = "Email must be provided"
          redirect "/users/password_reset"
          return
        else
          current_user.email = params[:email]
        end
      end
      
      current_user.password = params[:password]
      current_user.save
      flash[:notice] = "Password successfully set"
      redirect "/"
    else
      redirect "/forgot_password"
    end
  end

  get '/users' do
    set_params_page

    # Filter users by search params
    if params[:search] && !params[:search].empty?
      @users = User.where(:username => /#{params[:search]}/i)

    # Filter users by letter
    elsif params[:letter]
      if params[:letter] == "other"
        @users = User.where(:username => /^[^a-z0-9]/i)
      elsif
        @users = User.where(:username => /^#{params[:letter][0].chr}/i)
      end
    else
      @users = User
    end

    # Sort users alphabetically when filtering by letter
    if params[:letter]
      @users = @users.sort(:username)
    else
      @users = @users.sort(:created_at.desc)
    end

    @users = @users.paginate(:page => params[:page], :per_page => params[:per_page])

    @next_page = nil
    
    # If this would just accept params as is I wouldn't have to do this
    if params[:letter]
      @next_page = "?#{Rack::Utils.build_query :page => params[:page] + 1, :letter => params[:letter]}"
      
      if params[:page] > 1
        @prev_page = "?#{Rack::Utils.build_query :page => params[:page] + 1, :letter => params[:letter]}"
      else
        @prev_page = nil
      end
    else
      set_next_prev_page
    end

    haml :"users/index"
  end

  post '/users' do
    user = User.new params
    if user.save
      #this is really stupid.
      auth = {}
      auth['uid'] = session[:uid]
      auth['provider'] = session[:provider]
      auth['user_info'] = {}
      auth['user_info']['name'] = session[:name]
      auth['user_info']['nickname'] = session[:nickname]
      auth['user_info']['urls'] = {}
      auth['user_info']['urls']['Website'] = session[:website]
      auth['user_info']['description'] = session[:description]
      auth['user_info']['image'] = session[:image]
      auth['user_info']['email'] = session[:email]
      auth['credentials'] = {}
      auth['credentials']['token'] = session[:oauth_token]
      auth['credentials']['secret'] = session[:oauth_secret]

      Authorization.create_from_hash(auth, uri("/"), user)

      flash[:notice] = "Thanks! You're all signed up with #{user.username} for your username."
      session[:user_id] = user.id
      redirect '/'
    else
      flash[:notice] = "Oops! That username was taken. Pick another?"
      redirect '/users/new'
    end
  end

  # show user profile
  get "/users/:username" do
    set_params_page

    user = User.first :username => params[:username]
    if user.nil?
      #check for a case insensitive match and then redirect to the correct address
      username = Regexp.escape(params[:username])
      user = User.first :username => /^#{username}$/i
      if user.nil?
        raise Sinatra::NotFound
      else
        redirect "users/#{user.username}"
      end
    end
    @author = user.author
    #XXX: the following doesn't work for some reasond
    # @updates = user.feed.updates.sort{|a, b| b.created_at <=> a.created_at}.paginate(:page => params[:page], :per_page => params[:per_page])

    #XXX: this is not webscale
    @updates = Update.where(:feed_id => user.feed.id).order(['created_at', 'descending']).paginate(:page => params[:page], :per_page => params[:per_page])

    @next_page = nil
    set_next_prev_page

    haml :"users/show"
  end

  # user edits own profile
  get "/users/:username/edit" do
    @user = User.first :username => params[:username]
    if @user == current_user
      haml :"users/edit"
    else
      redirect "/users/#{params[:username]}"
    end
  end

  # user updates own profile
  put "/users/:username" do
    @user = User.first :username => params[:username]
    if @user == current_user
      if @user.edit_user_profile(params)
        flash[:notice] = "Profile saved!"
      else
        flash[:notice] = "Profile could not be saved!"
      end
    end
    redirect "/users/#{params[:username]}"
  end

  # an alias for the route of the feed
  get "/users/:username/feed" do
    feed = User.first(:username => params[:username]).feed
    redirect "/feeds/#{feed.id}.atom"
  end

  # This lets us see who is following.
  get '/users/:username/following' do
    set_params_page

    # XXX: case insensitive username
    feeds = User.first(:username => params[:username]).following

    @user = User.first(:username => params[:username])
    @authors = feeds.paginate(:page => params[:page], :per_page => params[:per_page], :order => :id.desc).map{|f| f.author}

    set_next_prev_page
    @next_page = nil unless params[:page]*params[:per_page] < feeds.count

    #build title
    title = ""
    title << "#{@user.username} is following"
    
    haml :"users/list", :locals => {:title => title}
  end

  get '/users/:username/following.json' do
    set_params_page

    users = User.first(:username => params[:username]).following
    authors = users.map { |user| user.author }
    authors.to_a.to_json
  end

  get '/users/:username/followers' do
    set_params_page

    feeds = User.first(:username => params[:username]).followers
    
    @user = User.first(:username => params[:username])
    @authors = feeds.paginate(:page => params[:page], :per_page => params[:per_page], :order => :id.desc).map{|f| f.author}

    set_next_prev_page
    @next_page = nil unless params[:page]*params[:per_page] < feeds.count

    #build title
    title = ""
    title << "#{@user.username}'s followers"

    haml :"users/list", :locals => {:title => title}
  end
  
  delete '/users/:username/auth/:provider' do
    user = User.first(:username => params[:username])
    if user
      auth = Authorization.first(:provider => params[:provider], :user_id => user.id)
      auth.destroy if auth
    end
    redirect "/users/#{params[:username]}/edit"
  end

end
