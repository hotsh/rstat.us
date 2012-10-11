class UserTwitterJsonDecorator < ApplicationDecorator
  decorates :user

  def as_json(options={})
    result = {
      :id => user.id,
      :username => user.username
    } 
    result
  end
end

