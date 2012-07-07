class AuthorJsonDecorator < ApplicationDecorator
  decorates :author

  # This article does a great job explaining why this is as_json:
  # http://jonathanjulian.com/2010/04/rails-to_json-or-as_json/
  def as_json(options = nil)
    author_decorator = AuthorDecorator.decorate(author)
    {
      :username => author.username,
      :name     => author.display_name,
      :website  => author_decorator.absolute_website_url,
      :bio      => author.bio,
      :avatar   => author_decorator.absolute_avatar_url
    }
  end
end