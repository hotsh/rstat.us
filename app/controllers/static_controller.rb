class StaticController < ApplicationController
  def homepage
    render :layout => false
  end

  def open_source
    @title = "open source"
  end

  def contact
    @title = "contact us"
  end
end
