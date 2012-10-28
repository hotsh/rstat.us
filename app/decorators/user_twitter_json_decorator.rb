class UserTwitterJsonDecorator < ApplicationDecorator
  decorates :user

  def as_json(options = {})
    unless options[:root_url]
      raise ArgumentError.new "root_url must be specified"
    end
    update = UpdateTwitterJsonDecorator.decorate(user.updates.last)
    author_decorator = AuthorDecorator.decorate(user.author)
    result = {
      :id => user.id,
      :username => user.username,
      :url => author_decorator.absolute_website_url,
      :screen_name => author.username,
      :name => author.display_name,
      :profile_image_url => author_decorator.absolute_avatar_url,
      :created_at => format_timestamp(author.created_at),
      :description => author.bio,
      :statuses_count => author.feed.updates.count,
      :friends_count => author.user.following.length,
      :followers_count => author.user.followers.length
    }
    result[:status] = update.as_json(:trim_user => true)  if options[:include_status] == true
    unless result[:profile_image_url].match(/^http/)
      resolved_url = (
                       URI(options[:root_url]) +
                       URI(result[:profile_image_url])
                     ).to_s
      result[:profile_image_url] = resolved_url
    end
    result
  end
end

