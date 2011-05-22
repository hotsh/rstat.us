class Rstatus

  helpers do
    # Manage page state
    def set_pagination
      set_params_page
      @updates = @updates.paginate( :page => params[:page], :per_page => params[:per_page], :order => :created_at.desc)
      set_pagination_buttons(@updates)  
    end
    
    
    # Render correct haml depending on request type
    def render_index(updates)
      @updates = updates
      set_pagination      
      haml :"updates/index", :layout => show_layout?
    end
  end

  before do
    @update_id, @update_text = "", ""
    
    # Set update form state correctly
    id = params.fetch(:reply) { params[:share] }
    if id
      u = Update.first(:id => id)
      @update_id = id
      @update_text = "@#{u.author.username} " if params[:reply]
      @update_text = "RS @#{u.author.username}: #{u.text}" if params[:share]        
    elsif params[:status]
      @update_text = params[:status]
    end
  end
  
  # Redirect anonymous users
  ['/timeline', '/replies'].each do |path|
    before path do
      redirect '/' unless current_user
    end
  end
  
  get '/timeline' do
    render_index(current_user.timeline(params))
  end

  get '/replies' do
    render_index(current_user.at_replies(params))
  end

  # Ahh, the classic 'world' view.
  get '/updates' do
    render_index(Update)
  end
  
  get "/hashtags/:tag" do
    @hashtag = params[:tag]    
    render_index(Update.hashtag_search(@hashtag, params))
  end

  get "/search" do
    @updates = []
    if params[:q]
      set_params_page
      @updates = Update.filter(params[:q]).paginate(:page => params[:page], :per_page => params[:per_page] || 20, :order => :created_at.desc)
      set_pagination_buttons(@updates)
    end
    haml :"updates/search"
  end

  # If you're POST-ing to /updates, it means you're making a new one. Woo-hoo!
  # This is what it's all built for.
  post '/updates' do
    # XXX: This should really be put into a model. Fat controller here!
    do_tweet = params[:tweet] == "1"
    do_facebook = params[:facebook] == "1"
    u = Update.new(:text => params[:text],
                   :referral_id => params[:referral_id],
                   :author => current_user.author,
                   :twitter => do_tweet,
                   :facebook => do_facebook)

    # add entry to user's feed
    current_user.feed.updates << u
    unless u.valid?
      flash[:notice] = u.errors.errors.values.join("\n")
    else
      current_user.feed.save
      current_user.save
      # tell hubs there is a new entry
      current_user.feed.ping_hubs(url(current_user.feed.url))

      flash[:notice] = "Update created."
    end

    if request.referrer
      redirect request.referrer
    else
      redirect "/"
    end
  end

  # Yay for REST-y CRUD! This just shows an update.
  get '/updates/:id' do
    @update = Update.first :id => params[:id]
    @referral = @update.referral
    haml :"updates/show", :layout => :'layout/update'
  end

  # Hopefully people don't delete a whole bunch of their updates, but if they
  # want to, this is where they come.
  delete '/updates/:id' do |id|
    update = Update.first :id => params[:id]

    # lolsecurity.
    if update.author == current_user.author
      update.destroy

      flash[:notice] = "Update Baleeted!"
      redirect "/"
    else
      flash[:notice] = "I'm afraid I can't let you do that, #{current_user.name}."
      redirect back
    end
  end

end
