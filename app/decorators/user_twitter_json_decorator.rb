class UserTwitterJsonDecorator < ApplicationDecorator
  decorates :user

  def as_json(options={})
    update = UpdateTwitterJsonDecorator.decorate(user.updates.last)
    result = {
      :id => user.id,
      :username => user.username,
      :status => update.as_json(options)
    } 
    result
  end
end

