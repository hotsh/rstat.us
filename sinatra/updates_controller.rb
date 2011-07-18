class Rstatus
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
end
