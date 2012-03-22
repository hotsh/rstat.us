class UsersController < ApplicationController
  before_filter :find_user, :only => [:show, :edit, :update, :feed, :following, :followers]

  def index
    @title = "users"
    set_params_page
    @authors = Author.search(params)

    unless @authors.empty?
      @authors = @authors.paginate(:page => params[:page], :per_page => params[:per_page])
      set_pagination_buttons(@authors)
    end
  end

  def show
    if @user.nil?
      render :file => "#{Rails.root}/public/404.html", :status => 404
    elsif @user.username != params[:id] # case difference
      redirect_to user_path(@user)
    else
      set_params_page

      @author  = @user.author
      @updates = @user.updates
      @updates = @updates.paginate(:page => params[:page], :per_page => params[:per_page])

      set_pagination_buttons(@updates)

      headers['Link'] = "<#{user_xrd_path(@user.author)}>; rel=\"lrdd\"; type=\"application/xrd+xml\""
    end
  end

  def edit
    # While it might be cool to edit other people's profiles, we probably
    # shouldn't let you do that. We're no fun.
    if @user == current_user
      render :edit
    else
      redirect_to user_path(params[:id])
    end
  end

  def update
    if @user == current_user
      response = @user.edit_user_profile(params)
      if response == true

        unless @user.email.blank? || @user.email_confirmed
          Notifier.send_confirm_email_notification(@user.email, @user.create_token)
          flash[:notice] = "A link to confirm your updated email address has been sent to #{@user.email}."
        else
          flash[:notice] = "Profile saved!"
        end

        redirect_to user_path(params[:id])

      else
        flash[:notice] = "Profile could not be saved: #{response}"
        render :edit
      end
    else
      redirect_to user_path(params[:id])
    end
  end

  def new
    params[:username] = session[:nickname]
    @user = User.new
  end

  def create
    params[:author] = Author.create_from_session!(session, params, root_url)

    @user = User.new :email    => params[:email],
                     :author   => params[:author],
                     :username => params[:username],
                     :password => params[:password]

    if @user.save
      Authorization.create_from_session!(session, @user)

      flash[:notice] = "Thanks! You're all signed up with #{@user.username} for your username."
      session[:user_id] = @user.id
      redirect_to root_path
    else
      render :new
    end
  end

  # This is pretty much the same thing as /feeds/your_feed_id.atom, but we
  # wanted to have a really nice URL for it, and not just the ugly one.
  def feed
    if @user
      redirect_to feed_path(@user.feed, :format => :atom)
    else
      render :file => "#{Rails.root}/public/404.html", :status => 404
    end
  end

  # Who do you think is a really neat person? This page will show it to the
  # world, so pick wisely!
  def following
    if @user.nil?
      render :file => "#{Rails.root}/public/404.html", :status => 404
    # If the username's case entered in the URL is different than the case
    # specified by that user, redirect to the case that the user prefers
    elsif @user.username != params[:id]
      redirect_to following_path(@user.username)
    else
      set_params_page

      @feeds = @user.following

      @feeds = @feeds.paginate(:page => params[:page], :per_page => params[:per_page], :order => :id.desc)

      set_pagination_buttons(@feeds)

      @authors = @feeds.map{|f| f.author}

      if @user == current_user
        title = "You're following"
      else
        title = "@#{@user.username} is following"
      end

      respond_to do |format|
        format.html { render "users/list", :locals => {:title => title} }
        format.json { render :json => @authors }
      end
    end
  end

  # This shows off how cool you are: I hope you've got the biggest number of
  # followers. Only one way to find out...
  def followers
    if @user.nil?
      render :file => "#{Rails.root}/public/404.html", :status => 404
    # If the username's case entered in the URL is different than the case
    # specified by that user, redirect to the case that the user prefers
    elsif @user.username != params[:id]
      redirect_to followers_path(@user.username)
    else
      set_params_page

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

      render "users/list", :locals => {:title => title}
    end
  end

  # If we can't find a user in mongo or the token is expired give
  # them some information and redirect.
  #
  # Once an email has been confirmed there is no reason to leave
  # the token set so let's nil it out. The reset token method runs
  # save so we don't need to do that anymore
  def confirm_email
    user = User.first(:perishable_token => params[:token])
    if user.nil?
      flash[:notice] = "Can't find User Account for this link."
      redirect_to root_path
    elsif user.token_expired?
      flash[:notice] = "Your link is no longer valid, please request a new one."
      redirect_to root_path
    else
      user.email_confirmed = true
      user.reset_perishable_token
      # Register a session for the user
      session[:user_id] = user.id
      flash[:notice] = "Email successfully confirmed."
      redirect_to root_path
    end
  end

  # Passwords can be reset by unauthenticated users by navigating to the forgot
  # password and page and submitting the email address they provided.
  def forgot_password_new
    render "login/forgot_password"
  end

  # We've got a pretty solid forgotten password implementation. It's simple:
  # the email address is looked up, if no user is found an error is provided.
  # If a user is found a token is generated and an email is sent to the user
  # with the url to reset their password. Users are then redirected to the
  # confirmation page to prevent repost issues
  def forgot_password_create
    user = User.first(:email => params[:email])
    if user.nil?
      flash[:notice] = "Your account could not be found, please check your email and try again."
      render "login/forgot_password"
    else
      Notifier.send_forgot_password_notification(user.email, user.create_token)
      # Redirect to try to avoid repost issues
      session[:fp_email] = user.email
      redirect_to forgot_password_confirm_path
    end
  end

  # Forgot password confirmation screen, displays email address that the email
  # was sent to
  def forgot_password_confirm
    @email = session.delete(:fp_email)
    render "login/forgot_password_confirm"
  end

  def reset_password_new
    if not logged_in?
      redirect_to forgot_password_path
    else
      render "login/password_reset"
    end
  end

  # Submitted passwords are checked for length and confirmation. Once the
  # password has been reset the user is redirected to /
  def reset_password_create
    user = nil

    if params[:token]
      user = User.first(:perishable_token => params[:token])
      if user and user.token_expired?
        user = nil
      end
    end

    unless user.nil?
      # XXX: yes, this is a code smell

      if params[:password].size == 0
        flash[:notice] = "Password must be present"
        redirect_to reset_password_path(params[:token])
        return
      end

      if params[:password] != params[:password_confirm]
        flash[:notice] = "Passwords do not match"
        redirect_to reset_password_path(params[:token])
        return
      end

      # TODO: This may be unreachable, since we don't allow password reset
      # without an email... look into this and remove this code if so.
      if user.email.nil?
        if params[:email].empty?
          flash[:notice] = "Email must be provided"
          redirect_to reset_password_path(params[:token])
          return
        else
          user.email = params[:email]
        end
      end

      user.password = params[:password]
      user.save
      flash[:notice] = "Password successfully set"
      redirect_to root_path
    else
      redirect_to forgot_password_path
    end
  end

  # Public reset password page, accessible via a valid token. Tokens are only
  # valid for 2 days and are unique to that user. The user is found using the
  # token and the reset password page is rendered
  def reset_password_with_token
    user = User.first(:perishable_token => params[:token])
    if user.nil? || user.token_expired?
      flash[:notice] = "Your link is no longer valid, please request a new one."
      redirect_to forgot_password_path
    else
      @token = params[:token]
      @user  = user
      render "login/password_reset"
    end
  end

  private

  def find_user
    @user = User.find_by_case_insensitive_username(params[:id])
  end
end
