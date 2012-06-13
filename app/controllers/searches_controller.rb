class SearchesController < ApplicationController
  def show
    @title = "search"
    @updates = []
    if params[:search]
      set_params_page
      leading_char = '\b'
      if params[:search][0] == '#'
        leading_char = ''
      end
      @updates = Update.where(:text => /#{leading_char}#{Regexp.quote(params[:search])}\b/i).paginate(:page => params[:page], :per_page => params[:per_page], :order => :created_at.desc)
      set_pagination_buttons(@updates)
    end
  end
end
