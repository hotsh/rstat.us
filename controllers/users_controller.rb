class Rstatus
  get '/users/confirm' do
    haml :"users/confirm"
  end

  get '/users/new' do
    haml :"users/new"
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
      @users = @users.sort(:username.desc)
    else
      @users = @users.sort(:created_at.desc)
    end

    @users = @users.paginate(:page => params[:page], :per_page => params[:per_page])

    @next_page = nil
    set_next_prev_page

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
  get "/users/:slug" do
    set_params_page

    user = User.first :username => params[:slug]
    if user.nil?
      raise Sinatra::NotFound
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
      redirect "/users/#{params[:username]}"

    else
      redirect "/users/#{params[:username]}"
    end
  end

  # an alias for the route of the feed
  get "/users/:name/feed" do
    feed = User.first(:username => params[:name]).feed
    redirect "/feeds/#{feed.id}.atom"
  end

  # This lets us see who is following.
  get '/users/:name/following' do
    set_params_page

    feeds = User.first(:username => params[:name]).following

    @users = feeds.paginate(:page => params[:page], :per_page => params[:per_page], :order => :id.desc).map{|f| f.author.user}

    set_next_prev_page
    @next_page = nil unless params[:page]*params[:per_page] < feeds.count

    haml :"users/list", :locals => {:title => "Following"}
  end

  get '/users/:name/following.json' do
    set_params_page

    users = User.first(:username => params[:name]).following
    authors = users.map { |user| user.author }
    authors.to_a.to_json
  end

  get '/users/:name/followers' do
    set_params_page

    feeds = User.first(:username => params[:name]).followers

    @users = feeds.paginate(:page => params[:page], :per_page => params[:per_page], :order => :id.desc).map{|f| f.author.user}

    set_next_prev_page
    @next_page = nil unless params[:page]*params[:per_page] < feeds.count

    haml :"users/list", :locals => {:title => "Followers"}
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
