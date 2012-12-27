require 'uri'

class FeedService
  def initialize(target_feed, current_node_domain = nil)
    @target_feed  = target_feed
    @current_node_domain = current_node_domain
  end

  def find_or_create!
    find_feed_by_id            ||
    find_feed_by_username      ||
    find_feed_by_remote_url    ||
    create_feed_from_feed_data
  end

  private

  def find_feed_by_id
    Feed.first(:id => @target_feed)
  end

  def find_feed_by_username
    username, domain = @target_feed.split /@/

    if @current_node_domain && domain == URI(@current_node_domain).host
      u = User.find_by_case_insensitive_username(username)
      u && u.author.feed
    end
  end

  def find_feed_by_remote_url
    feed_data = get_feed_data_for_target
    Feed.first(:remote_url => feed_data.url)
  end

  def create_feed_from_feed_data
    feed_data = get_feed_data_for_target
    Feed.create_and_populate!(feed_data)
  end

  def get_feed_data_for_target
    SubscriberToFeedDataConverter.new(@target_feed).get_feed_data!
  end
end