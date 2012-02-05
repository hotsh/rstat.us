class StaticController < ApplicationController
  def homepage
    render :layout => false
  end
end
