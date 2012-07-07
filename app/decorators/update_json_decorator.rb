class UpdateJsonDecorator < ApplicationDecorator
  decorates :update

  def as_json(options = nil)
    author_json_decorator = AuthorJsonDecorator.decorate(update.author)
    {
      :user => author_json_decorator,
      :text => update.text,
      :created_at => update.created_at,
      :url => update.url
    }

  end
end
