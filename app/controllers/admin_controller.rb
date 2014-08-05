class AdminController < ApplicationController
  def index
      logger.debug "current_user:"
      logger.debug current_user
    return if admin_only!

    @admin = admin_info
  end

  def update
    logger.debug session
      logger.debug "current_user:"
      logger.debug current_user
    return if admin_only!

    admin_info.multiuser = (params["multiuser"] == "on")
    admin_info.save

    redirect_to root_path
  end
end
