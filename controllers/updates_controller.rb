class Rstatus

  # Ahh, the classic 'world' view.
  get '/updates' do
    @updates = Update.paginate( :page => params[:page], :per_page => params[:per_page] || 20, :order => :created_at.desc)

    if @updates.next_page
      @next_page = "?#{Rack::Utils.build_query :page => @updates.next_page}"
    end

    if @updates.previous_page
      @prev_page = "?#{Rack::Utils.build_query :page => @updates.previous_page}"
    end

    haml :world
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
    current_user.feed.save
    current_user.save

    # tell hubs there is a new entry
    current_user.feed.ping_hubs(url(current_user.feed.url))

    if params[:text].length < 1
      flash[:notice] = "Your status is too short!"
    elsif params[:text].length > 140
      flash[:notice] = "Your status is too long!"
    else
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
    haml :"updates/show", :layout => :'updates/layout'
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
