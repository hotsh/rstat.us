class SearchesController < ApplicationController
  def show
    @title = "search"
    @updates = []
    set_params_page

    # The use of `from` and `size` here are due to a bug involving
    # tire, rails, mongo_mapper, and elasticsearch.
    # See https://github.com/karmi/tire/issues/463.
    from = params[:page].to_i <= 1 ? 0 : (params[:per_page].to_i * (params[:page].to_i-1))
    size = params[:per_page]

    @updates = Update.search(
      params[:search],
      {:load => true, :from => from, :size => size }
    )
    set_pagination_buttons(@updates, :search => params[:search], :per_page => params[:per_page])
  end
end
