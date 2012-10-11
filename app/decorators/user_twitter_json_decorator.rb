class UserTwitterJsonDecorator < ApplicationDecorator
  decorates :user

  def as_json(options={})
    result = {
      :id => user.id,
      :username => user.username
    } 

    if options[:include_entities]
      # TODO populate response[:entities]
      result[:entities] = {
        :urls => [],
        :hashtags => [],
        :user_mentions => []
      }
    end
    result
  end
end

