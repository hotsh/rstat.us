class FeedService
  def initialize(target_feed)
    @target_feed  = target_feed
  end

  def find_or_create!
    find_feed_by_id             ||
    find_feed_by_remote_url     ||
    create_feed_from_feed_data
  end

  private

  def find_feed_by_id
    Feed.first(:id => @target_feed)
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