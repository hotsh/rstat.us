class UsersController < ApplicationController
  before_filter :find_user, :only => [:show, :edit, :update, :feed, :following, :followers]
  before_filter :require_user, :only => [:edit, :update, :confirm_delete, :destroy]

  def index
    @title = "users"
    set_params_page
    if params[:search].blank?
      @authors = Author.paginate(:page => params[:page], :per_page => params[:per_page])
    else
      begin
        @authors = Author.search(params)
      rescue RegexpError
        flash[:error] = "Please enter a valid search term"
        redirect_to users_path and return
      end

      unless @authors.empty?
        @authors = @authors.paginate(:page => params[:page], :per_page => params[:per_page])
        set_pagination_buttons(@authors, :search => params[:search])
      end
    end
  end

  def show
    if @user.nil?
      render :file => "#{Rails.root}/public/404", :status => 404
    elsif @user.username != params[:id] # case difference
      @title = @user.username
      redirect_to user_path(@user)
    else
      set_params_page
      @title = @user.username
      @author  = @user.author
      @updates = @user.updates
      @updates = @updates.paginate(:page => params[:page], :per_page => params[:per_page])

      set_pagination_buttons(@updates)

      headers['Link'] = "<#{user_xrd_path(@user.author)}>; rel=\"lrdd\"; type=\"application/xrd+xml\""

      respond_to do |format|
        format.html
        format.json {
          render :json => @updates.map{ |u| UpdateJsonDecorator.decorate(u) }
        }
      end

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
      @user.update_profile!(params)

      unless @user.errors.any?
        unless @user.email.blank? || @user.email_confirmed
          Notifier.send_confirm_email_notification(@user.email, @user.create_token)
          flash[:notice] = "A link to confirm your updated email address has been sent to #{@user.email}."
        else
          flash[:notice] = "Profile saved!"
        end

        redirect_to user_path(@user)
      else
        error_message = render_to_string :partial => 'users/errors',
                                         :locals => {:user => @user}
        flash[:error] = error_message.html_safe

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
      sign_in(@user)
      redirect_to root_path
    else
      render :new
    end
  end

  def autocomplete
    @json = current_user.autocomplete(params[:term])

    render :json => @json
  end

  # This is pretty much the same thing as /feeds/your_feed_id.atom, but we
  # wanted to have a really nice URL for it, and not just the ugly one.
  def feed
    if @user
      redirect_to feed_path(@user.feed, :format => :atom)
    else
      render :file => "#{Rails.root}/public/404", :status => 404
    end
  end

  # Who do you think is a really neat person? This page will show it to the
  # world, so pick wisely!
  def following
    if @user.nil?
      render :file => "#{Rails.root}/public/404", :status => 404
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
        format.html { render "users/list", :locals => {:title => title, :list_class => "friends"} }
        format.json { render :json => @authors }
      end
    end
  end

  # This shows off how cool you are: I hope you've got the biggest number of
  # followers. Only one way to find out...
  def followers
    if @user.nil?
      render :file => "#{Rails.root}/public/404", :status => 404
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

      render "users/list", :locals => {:title => title, :list_class => "followers"}
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
      flash[:error] = "Can't find User Account for this link."
      redirect_to root_path
    elsif user.token_expired?
      flash[:error] = "Your link is no longer valid, please request a new one."
      redirect_to root_path
    else
      user.email_confirmed = true
      user.reset_perishable_token
      # Register a session for the user
      sign_in(user)
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
    unless params[:email] =~ /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i
      flash[:error] = "You didn't enter a correct email address. Please check your email and try again."
      return render "login/forgot_password"
    end

    user = User.first(:email => params[:email])

    if user.nil?
      flash[:error] = "Your account could not be found, please check your email and try again."
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
    user = User.first(:perishable_token => params[:token]) if params[:token]
    user = nil if user && user.token_expired?

    redirect_to forgot_password_path unless user
    password_service = PasswordService.new(user, params)

    if password_service.invalid?
      flash[:error] = password_service.message
      url = reset_password_path(params[:token])
    else
      password_service.reset_password
      flash[:notice] = "Password successfully set"
      url = root_path
    end

    redirect_to url
  end

  # Public reset password page, accessible via a valid token. Tokens are only
  # valid for 2 days and are unique to that user. The user is found using the
  # token and the reset password page is rendered
  def reset_password_with_token
    user = User.first(:perishable_token => params[:token])
    if user.nil? || user.token_expired?
      flash[:error] = "Your link is no longer valid, please request a new one."
      redirect_to forgot_password_path
    else
      @token = params[:token]
      @user  = user
      render "login/password_reset"
    end
  end

  def confirm_delete
  end

  def destroy
    if current_user && params[:username_confirmation] == current_user.username
      current_user.destroy
      sign_out
      flash[:notice] = "Your account has been deleted. We're sorry to see you go."
      redirect_to root_path
    elsif current_user
      flash[:notice] = "Nothing was deleted since you did not type your username."
      redirect_to edit_user_path
    else
      redirect_to root_path
    end
  end

  private

  def find_user
    if @user = User.find_by_case_insensitive_username(params[:id])
      @user = UserDecorator.decorate(@user)
    end
  end
end
