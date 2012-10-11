class UserTwitterJsonDecorator < ApplicationDecorator
  decorates :user

  def as_json(options={})
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
    result[:profile_image_url].prepend("http://rstat.us") if result[:profile_image_url] == ActionController::Base.helpers.asset_path(RstatUs::DEFAULT_AVATAR)
    result
  end
end

