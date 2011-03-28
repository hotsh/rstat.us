class Rstatus

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

  post '/updates' do
    do_tweet = params[:tweet] == "1"
    do_facebook = params[:facebook] == "1"
    u = Update.new(:text => params[:text],
                   :referral_id => params[:referral_id],
                   :author => current_user.author,
                   :twitter => do_tweet,
                   :facebook => do_facebook)

    # and entry to user's feed
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

    redirect "/"
  end

  get '/updates/:id' do
    @update = Update.first :id => params[:id]
    @referral = @update.referral
    haml :"updates/show", :layout => :'updates/layout'
  end

  delete '/updates/:id' do |id|
    update = Update.first :id => params[:id]

    if update.author == current_user.author
      update.destroy

      flash[:notice] = "Update Baleeted!"
      redirect "/"
    else
      flash[:notice] = "I'm afraid I can't let you do that, " + current_user.name + "."
      redirect back
    end
  end

end
