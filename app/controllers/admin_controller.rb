class AdminController < ApplicationController
  def index
    return if admin_only!

    @admin = admin_info
  end

  def update
    return if admin_only!

    admin_info.multiuser = params.has_key?("multiuser")
    admin_info.save

    redirect_to root_path
  end
end
