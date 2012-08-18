class UpdateTwitterJsonDecorator < ApplicationDecorator
  decorates :update

  def as_json(options={})
    referral = (update.referral ? update.referral : nil)
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
        :id_str => update.id.to_s,
        :id => update.id
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
    unless result[:trim_user]
      # TODO expand response[:user]
    end
    result
  end

  def format_timestamp(timestamp)
    timestamp.strftime("%a %b %d %H:%M:%S %z %Y")
  end
end

