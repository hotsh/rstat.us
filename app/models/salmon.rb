class Salmon
  def self.interpret_entry(body, params = {})
    raise(ArgumentError, "request body can't be empty") if body.empty?

    feed   = Salmon.find_feed(params[:feed_id])
    salmon = Salmon.parse(body)

    raise(ArgumentError, "can't parse salmon envelope") if salmon.nil?
  end

  # Isolating calls to external classes so we can stub these methods in test
  # and not have to load rails!
  def self.find_feed(id)
    # Using the bang version so we get a MongoMapper::DocumentNotFound exception
    Feed.find!(id)
  end

  def self.parse(body)
    OStatus::Salmon.from_xml body
  end
end