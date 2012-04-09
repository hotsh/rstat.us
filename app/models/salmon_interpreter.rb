class SalmonInterpreter
  def initialize(body, params = {})
    raise(ArgumentError, "request body can't be empty") if !body || body.empty?

    @feed = SalmonInterpreter.find_feed(params[:feed_id])

    @salmon = SalmonInterpreter.parse(body)
    raise(ArgumentError, "can't parse salmon envelope") if @salmon.nil?

    @root_url = params[:root_url]
  end

  def interpret
    # We can ignore salmon for authors that have a local user account.
    return true if local_user?

    @author = find_or_initialize_author

    raise RstatUs::InvalidSalmonMessage unless message_verified?

    if @author.new?
      @author.save!
    end
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

  private

  def find_or_initialize_author
    author = Author.first :remote_url => author_uri

    # This author is unknown to us, so let's create a new Author
    unless author
    end

    author
  end

  def message_verified?
    @salmon.verified?(@author.retrieve_public_key)
  end

  def local_user?
    author_uri.start_with?(@root_url)
  end

  def author_uri
    @salmon.entry.author.uri
  end
end