# The Admin model contains system settings.

class Admin
  include MongoMapper::Document

  # Whether or not user accounts can be created
  key :multiuser, Boolean

  def can_create_user?
    return !(User.count > 0 && !self.multiuser)
  end
end
