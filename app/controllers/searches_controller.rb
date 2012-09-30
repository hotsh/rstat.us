class SearchesController < ApplicationController
  def show
    @title = "search"
    @updates = []
    if params[:search]
      set_params_page

      @updates = Update.search(
        params[:search],
        {:load => true}.merge(params)
      )
      set_pagination_buttons(@updates, :search => params[:search])
    end
  end
end
