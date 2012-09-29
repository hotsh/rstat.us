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

      @updates = Update.search(params[:search], load:true)
      set_pagination_buttons(@updates, :search => params[:search])
    end
  end
end
