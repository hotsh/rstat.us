class StaticController < ApplicationController
  def homepage
    @list_class = ""
    render :layout => false
  end

  def open_source
    @title = "open source"
  end

  def developers
    @title = "developers"
  end

  def about
    @title = "about us"
  end

  def contact
    @title = "contact us"
  end
end
