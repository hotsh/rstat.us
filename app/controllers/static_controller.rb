class StaticController < ApplicationController
  before_filter :require_user, :only => :follow

  def homepage
    @list_class = ""
    render :layout => false
  end

  def open_source
    @title = "open source"
  end

  def about
    @title = "about us"
  end

  def contact
    @title = "contact us"
  end

  def follow
    @title = "follow a user"
  end
end
