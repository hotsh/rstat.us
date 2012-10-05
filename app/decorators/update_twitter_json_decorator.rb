class UpdateTwitterJsonDecorator < ApplicationDecorator
  decorates :update

  def as_json(options={})
    referral = (update.referral ? update.referral : nil)
    author = update.author
    result = {
      :id => update.id,
      :id_str => update.id.to_s,
      :coordinates => nil,
      :created_at => format_timestamp(update.created_at),
      :truncated => false,
      :favorited => false,
      :in_reply_to_user_id_str => nil,
      :contributors => nil,
      :text => update.text,
      :retweet_count => 0,
      :in_reply_to_status_id => (referral ? referral.id : nil),
      :in_reply_to_status_id_str => (referral ? referral.id.to_s : nil),
      :source => "<a href=\"http://rstat.us\" rel=\"nofollow\">rstat.us</a>",
      :in_reply_to_screen_name => nil,
      :place => nil,
      :user => {
        :id_str => author.id.to_s,
        :id => author.id
      }
    }
    if options[:include_entities]
      # TODO populate response[:entities]
      result[:entities] = {
        :urls => [],
        :hashtags => [],
        :user_mentions => []
      }
    end
    unless options[:trim_user]
      author_decorator = AuthorDecorator.decorate(author)
      author_info = {
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
      author_info[:profile_image_url].prepend("http://rstat.us") if author_info[:profile_image_url] == ActionController::Base.helpers.asset_path(RstatUs::DEFAULT_AVATAR)
      result[:user].merge!(author_info)
    end
    result
  end

  def format_timestamp(timestamp)
    timestamp.strftime("%a %b %d %H:%M:%S %z %Y")
  end
end

