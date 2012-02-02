# The User model contains all of the information that a particular user of our
# site needs: their username/password, etc. It all comes from here. Even users
# that sign up via Twitter get a User model, though it's a bit empty in that
# particular case.

require 'crypto'

class User
  require 'digest/md5'

  include MongoMapper::Document

  # Associations
  # XXX: These don't seem to be getting set when you sign up with Twitter, etc?
  many :authorizations, :dependant => :destroy
  belongs_to :author
  key :author_id, ObjectId

  # Users MUST have a username
  key :username, String, :required => true

  # Users MIGHT have an email
  key :email, String
  key :email_confirmed, Boolean

  # RSA for salmon usage
  key :private_key, String

  # Required for confirmation
  key :perishable_token, String

  validate :email_already_confirmed
  validates_uniqueness_of :username, :allow_nil => :true, :case_sensitive => false

  # The maximum is arbitrary
  # Twitter has 15, let's be different
  validates_length_of :username, :maximum => 17, :message => "must be 17 characters or fewer."

  # Validate users don't have special characters in their username
  validate :no_malformed_username

  # This will establish other entities related to the User
  after_create :finalize

  def feed
    self.author.feed
  end

  def updates
    self.author.feed.updates.sort(:created_at.desc)
  end

  # Before a user is created, we will generate some RSA keys
  def generate_rsa_pair
    keypair = Crypto.generate_keypair

    self.author.public_key = keypair.public_key
    self.author.save

    self.private_key = keypair.private_key
  end

  # Retrieves a valid RSA::KeyPair for the User's private key
  def to_rsa_keypair
    Crypto.make_rsa_keypair(nil, private_key)
  end

  # After a user is created, create the feed and reset the token
  def finalize
    create_feed
    generate_rsa_pair
    reset_perishable_token
  end

  # Generate a multi-use token for account confirmation and password resets
  def set_perishable_token
    self.perishable_token = Digest::MD5.hexdigest( rand.to_s )
    save
  end

  # Reset the perishable token
  def reset_perishable_token
    self.perishable_token = nil
    save
  end

  # Determines a url that leads to the profile of this user
  def url
    "/users/#{feed.author.username}"
  end

  # Returns true when this user has a twitter authorization
  def twitter?
    has_authorization?(:twitter)
  end

  # Returns the twitter authorization
  def twitter
    get_authorization(:twitter)
  end

  # Check if a a user has a certain authorization by providing the associated
  # provider
  def has_authorization?(auth)
    a = Authorization.first(:provider => auth.to_s, :user_id => self.id)
    #return false if not authenticated and true otherwise.
    !a.nil?
  end

  # Get an authorization by providing the assoaciated provider
  def get_authorization(auth)
    Authorization.first(:provider => auth.to_s, :user_id => self.id)
  end

  # Users follow many feeds
  key :following_ids, Array
  many :following, :in => :following_ids, :class_name => 'Feed'

  # Users have feeds that follow them
  key :followers_ids, Array
  many :followers, :in => :followers_ids, :class_name => 'Feed'

  # A particular feed follows this user
  def followed_by!(f)
    followers << f
    save
  end

  # A particular feed unfollows this user
  def unfollowed_by!(f)
    followers_ids.delete(f.id)
    save
  end

  # Follow a particular feed
  def follow!(f)
    # can't follow yourself
    if f == self.feed
      return
    end

    following << f
    save

    if f.local?
      # Add the inverse relationship
      followee = User.first(:author_id => f.author.id)
      followee.followed_by! self.feed
    else
      # Queue a notification job
      self.delay.send_follow_notification(f.id)
    end
    f
  end

  # Send Salmon notification so that the remote user
  # knows this user is following them
  def send_follow_notification(to_feed_id)
    f = Feed.first :id => to_feed_id

    salmon = OStatus::Salmon.from_follow(author.to_atom, f.author.to_atom)

    envelope = salmon.to_xml self.to_rsa_keypair

    # Send envelope to Author's Salmon endpoint
    uri = URI.parse(f.author.salmon_url)
    http = Net::HTTP.new(uri.host, uri.port)
    res = http.post(uri.path, envelope, {"Content-Type" => "application/magic-envelope+xml"})
  end

  # unfollow takes a feed (since it is guaranteed to exist)
  def unfollow!(followed_feed)
    following_ids.delete(followed_feed.id)
    save
    if followed_feed.local?
      followee = User.first(:author_id => followed_feed.author.id)
      followee.unfollowed_by!(self.feed)
    else
      # Queue a notification job
      self.delay.send_unfollow_notification(followed_feed.id)
    end
  end

  # Send Salmon notification so that the remote user
  # knows this user has stopped following them
  def send_unfollow_notification(to_feed_id)
    f = Feed.first :id => to_feed_id

    salmon = OStatus::Salmon.from_unfollow(author.to_atom, f.author.to_atom)

    envelope = salmon.to_xml self.to_rsa_keypair

    # Send envelope to Author's Salmon endpoint
    uri = URI.parse(f.author.salmon_url)
    http = Net::HTTP.new(uri.host, uri.port)
    res = http.post(uri.path, envelope, {"Content-Type" => "application/magic-envelope+xml"})
  end

  # Send an update to a remote user as a Salmon notification
  def send_mention_notification(update_id, to_feed_id)
    f = Feed.first :id => to_feed_id
    u = Update.first :id => update_id

    base_uri = "http://#{author.domain}/"
    salmon = OStatus::Salmon.new(u.to_atom(base_uri))

    envelope = salmon.to_xml self.to_rsa_keypair

    # Send envelope to Author's Salmon endpoint
    uri = URI.parse(f.author.salmon_url)
    http = Net::HTTP.new(uri.host, uri.port)
    res = http.post(uri.path, envelope, {"Content-Type" => "application/magic-envelope+xml"})
  end

  def followed_by?(f)
    followers.include? f
  end

  def following_feed?(f)
    following.include? f
  end

  def following_author?(author)
    following.include?(author.feed)
  end

  def following_url?(feed_url)
    # Handle possibly created multiple feeds for the same remote_url
    existing_feeds = Feed.all(:remote_url => feed_url)

    # local feed?
    if existing_feeds.empty? and feed_url.start_with?("http://#{author.domain}/")
      feed_id = feed_url[/\/feeds\/(.+)$/,1]
      existing_feeds = [Feed.first(:id => feed_id)]
    end

    if existing_feeds.empty?
      false
    else
      # Intersect the feeds we're following and the possibly
      # created multiple feeds for the remote
      !(following & existing_feeds).empty?
    end
  end

  timestamps!

  # Retrieve the list of Updates in the user's timeline
  def timeline(params = nil)
    following_plus_me = following.map(&:author_id)
    following_plus_me << self.author.id
    Update.where(:author_id => following_plus_me).order(['created_at', 'descending'])
  end

  # Retrieve the list of Updates that are replies to this user
  def at_replies(params)
    Update.where(:text => /^@#{Regexp.quote(username)}\b/).order(['created_at', 'descending'])
  end

  # User MUST be confirmed
  key :status

  # Users have a passwork
  key :hashed_password, String
  key :perishable_token_set, DateTime, :default => nil

  # Store the hash of the password
  def password=(pass)
    self.hashed_password = BCrypt::Password.create(pass, :cost => 10)
  end

  # Create a new perishable token and set the date the token was
  # sent so tokens can be expired after 2 days. This is used for
  # password resets and email confirmations
  def create_token
    self.perishable_token_set = DateTime.now
    set_perishable_token
    self.perishable_token
  end

  # Set a new password, clear the date the password reset token was sent and
  # reset the perishable token
  def reset_password(pass)
    self.password = pass
    self.perishable_token_set = nil
    reset_perishable_token
  end

  # Authenticate the user by checking their credentials
  def self.authenticate(username, pass)
    user = User.find_by_case_insensitive_username(username)
    return nil if user.nil?
    return user if BCrypt::Password.new(user.hashed_password) == pass
    nil
  end

  # Edit profile information
  def edit_user_profile(params)
    unless params[:password].nil? or params[:password].empty?
      if params[:password] == params[:password_confirm]
        self.password = params[:password]
        self.save
      else
        return "Passwords must match"
      end
    end

    self.email_confirmed = self.email == params[:email]
    self.email = params[:email]

    self.save

    author.name    = params[:name]
    author.email   = params[:email]
    author.website = params[:website]
    author.bio     = params[:bio]
    author.save

    # TODO: Send out notice to other nodes
    # To each remote domain that is following you via hub
    # and to each remote domain that you follow via salmon
    author.feed.ping_hubs

    return true
  end

  # A better name would be very welcome.
  def self.find_by_case_insensitive_username(username)
    User.first(:username => /^#{Regexp.escape(username)}$/i)
  end

  private

  def create_feed
    f = Feed.create(
      :author => self.author
    )

    self.author.save

    save
  end

  def no_malformed_username
    unless (username =~ /[@!"#$\%&'()*,^~{}|`=:;\\\/\[\]\s?]/).nil? && (username =~ /^[.]/).nil? && (username =~ /[.]$/).nil? && (username =~ /[.]{2,}/).nil?
      errors.add(:username, "contains restricted characters. Try sticking to letters, numbers, hyphens and underscores.")
    end
  end

  def email_already_confirmed
    if User.where(:email => self.email,
      :email_confirmed => true,
      :username.ne => self.username).count > 0
      errors.add(:email, "is already taken.")
    end
  end
end
