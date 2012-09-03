# Avatar management
class AvatarController < ApplicationController
  before_filter :require_user

  # Let the user remove the avatar that was saved as their author.image_url
  # in case they'd rather use a gravatar with their email address
  def destroy
    current_user.author.unset(:image_url)
    redirect_to edit_user_path(current_user)
  end
end