class AdminController < ApplicationController
  before_filter :admin_only!

  def index
    @admin = admin_info
  end

  def update
    admin_info.multiuser = params.has_key?("multiuser")
    admin_info.save

    redirect_to root_path
  end
end
