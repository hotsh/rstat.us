class StaticController < ApplicationController
  def homepage
    @list_class = "all"
    render :layout => false
  end

  def open_source
    @title = "open source"
  end

  def contact
    @title = "contact us"
  end
end
