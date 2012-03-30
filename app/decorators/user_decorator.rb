class UserDecorator < ApplicationDecorator
  decorates :user
  decorates_association :author
end
