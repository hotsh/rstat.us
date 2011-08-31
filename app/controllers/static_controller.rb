class StaticController < ApplicationController
  def open_source
  end

  def follow
    render "static/follow.html"
  end

  def contact
  end

  def help
  end

  def homepage
    render :layout => false
  end

end
