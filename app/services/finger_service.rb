class FingerService

  attr_reader :feed_data

  def initialize(target)
    @target     = target
    @feed_data  = FeedData.new
  end

  def finger!
    # TODO: ensure caching of finger lookup.
    data = FingerData.new(Redfinger.finger(@target))
    @feed_data.url          = data.url
    @feed_data.finger_data  = data
    @feed_data
  # TODO: other exceptions to rescue; check what Redfinger raises
  rescue RestClient::ResourceNotFound
    raise RstatUs::InvalidSubscribeTo
  rescue SocketError
    raise RstatUs::InvalidSubscribeTo
  end

end