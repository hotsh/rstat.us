class UsersController < ApplicationController

  def index
    set_params_page
    # Filter users by search params
    if params[:search] && !params[:search].empty?
      @authors = Author.where(:username => /#{params[:search]}/i)

    # Filter and sort users by letter
    elsif params[:letter]
      if params[:letter] == "other"
        @authors = Author.where(:username => /^[^a-z0-9]/i)
      elsif params[:letter].empty?
        raise "EMPTY"
      else
        @authors = Author.where(:username => /^#{params[:letter][0].chr}/i)
      end
      @authors = @authors.sort(:username)

    # Otherwise get all users and sort by creation date
    else
      @authors = Author
      @authors = @authors.sort(:created_at.desc)
    end

    @authors = @authors.paginate(:page => params[:page], :per_page => params[:per_page])

    if params[:letter] && !params[:letter].empty?
      set_pagination_buttons(@authors, :letter => params[:letter])
    else
      set_pagination_buttons(@authors)
    end
    haml :"users/index"
  end

  def show
    set_params_page

    user = User.first :username => params[:id]
    if user.nil?
      #check for a case insensitive match and then redirect to the correct address
      username = Regexp.escape(params[:id])
      user = User.first :username => /^#{username}$/i
      if user.nil?
        raise Sinatra::NotFound
      else
        redirect "users/#{user.username}"
      end
    end
    @author = user.author
    @updates = Update.where(:feed_id => user.feed.id).order(['created_at', 'descending'])
    @updates = @updates.paginate(:page => params[:page], :per_page => params[:per_page])
    set_pagination_buttons(@updates)

    headers['Link'] = "<#{user_xrd_path(user.author.username)}>; rel=\"lrdd\"; type=\"application/xrd+xml\""
  end

  def edit
    @user = User.first :username => params[:id]
    puts @user
    puts current_user
    # raise params.inspect

    # While it might be cool to edit other people's profiles, we probably
    # shouldn't let you do that. We're no fun.
    if @user == current_user
      render :edit
    else
      redirect_to user_path(params[:id])
    end
  end

  def update
    @user = User.first :username => params[:username]
    if @user == current_user
      response = @user.edit_user_profile(params)
      if response == true
        flash[:notice] = "Profile saved!"
        redirect "/users/#{params[:username]}"

        unless @user.email_confirmed
          # Generate same token as password reset....
          Notifier.send_confirm_email_notification(@user.email, @user.set_perishable_token)
          flash[:notice] = "A link to confirm your updated email address has been sent to #{@user.email}."
        else
          flash[:notice] = "Profile saved!"
        end

      else
        flash[:notice] = "Profile could not be saved: #{response}"
        haml :"users/edit"
      end
    else
      redirect "/users/#{params[:username]}"
    end
  end

  def new
  end

  def create
    # this is really stupid.
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

    params[:author] = Author.create_from_hash! auth, uri("/")

    @user = User.new params
    if @user.save
      Authorization.create_from_hash(auth, uri("/"), @user)

      flash[:notice] = "Thanks! You're all signed up with #{@user.username} for your username."
      session[:user_id] = @user.id
      redirect_to root_path
    else
      render :new
    end
  end

  #uuuhhhh
  def create_from_email
    u = User.create(:email => params[:email],
                    :status => "unconfirmed")
    u.set_perishable_token

    if development?
      puts uri("/") + "confirm/#{u.perishable_token}"
    else
      Notifier.send_signup_notification(params[:email], u.perishable_token)
    end
  end

  # This is pretty much the same thing as /feeds/your_feed_id, but we
  # wanted to have a really nice URL for it, and not just the ugly one.
  # Since it's only two lines, we don't bother to do a redirect, and
  # it's arguably better to display them as two different resources.
  # Whatevs.
  def feed
    feed = User.first(:username => params[:username]).feed
    redirect "/feeds/#{feed.id}.atom"
  end

  # Who do you think is a really neat person? This page will show it to the
  # world, so pick wisely!
  def following
    set_params_page

    # XXX: case insensitive username
    @user = User.first(:username => params[:username])
    @feeds = @user.following

    @feeds = @feeds.paginate(:page => params[:page], :per_page => params[:per_page], :order => :id.desc)

    set_pagination_buttons(@feeds)

    @authors = @feeds.map{|f| f.author}

    if @user == current_user
      title = "You're following"
    else
      title = "@#{@user.username} is following"
    end

    haml :"users/list", :locals => {:title => title}
  end

  # This shows off how cool you are: I hope you've got the biggest number of
  # followers. Only one way to find out...
  def followers
    set_params_page

    # XXX: case insensitive username
    @user = User.first(:username => params[:username])
    @feeds = @user.followers

    @feeds = @feeds.paginate(:page => params[:page], :per_page => params[:per_page], :order => :id.desc)

    set_pagination_buttons(@feeds)

    @authors = @feeds.map{|f| f.author}

    #build title
    if @user == current_user
      title = "Your followers"
    else
      title = "@#{@user.username}'s followers"
    end

    haml :"users/list", :locals => {:title => title}
  end

end
