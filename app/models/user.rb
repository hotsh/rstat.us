# The User model contains all of the information that a particular user of our
# site needs: their username/password, etc. It all comes from here. Even users
# that sign up via Twitter get a User model, though it's a bit empty in that
# particular case.

require 'crypto'
require 'bcrypt'

class User
  require 'digest/md5'

  include MongoMapper::Document

  # Associations
  # XXX: These don't seem to be getting set when you sign up with Twitter, etc?
  many :authorizations, :dependent => :destroy
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

  # Tokens are valid for 2 days, they're checked against this
  key :perishable_token_set, DateTime, :default => nil

  # Global preference set via user's profile controlling the state of the Post to Twitter checkbox
  key :always_send_to_twitter, Integer, :default => 1

  validate :email_already_confirmed
  validates_uniqueness_of :username,
                          :allow_nil => :true,
                          :case_sensitive => false,
                          :message => "has already been taken."

  # The maximum is arbitrary
  # Twitter has 15, let's be different
  validates_length_of :username,
                      :maximum => 17,
                      :message => "must be 17 characters or fewer."

  # Validate users don't have special characters in their username
  validate :no_malformed_username

  # This will establish other entities related to the User
  after_create :finalize

  # Mongo_mapper does not run :dependent => :destroy on belongs_to
  # relationships, so clean up manually.
  # https://github.com/jnunemaker/mongomapper/blob/master/test/functional/associations/test_belongs_to_proxy.rb#L155
  before_destroy :clean_up

  def clean_up
    self.author.destroy
  end

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
    self.perishable_token = SecureRandom.hex
    save
  end

  # Reset the perishable token and the date it was set to nil
  def reset_perishable_token
    self.perishable_token = nil
    self.perishable_token_set = nil
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
  def follow!(target_feed)
    return false if target_feed == self.feed # can't follow yourself

    self.following << target_feed
    self.save

    if target_feed.local?
      # Add the inverse relationship
      followee = User.first(:author_id => target_feed.author.id)
      followee.followed_by! self.feed
    else
      # Queue a notification job
      self.delay.send_follow_notification(target_feed.id)
    end

    target_feed
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
    if uri.scheme == "https"
      http.use_ssl = (uri.port == 443)
    end
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
    if uri.scheme == "https"
      http.use_ssl = (uri.port == 443)
    end
    res = http.post(uri.path, envelope, {"Content-Type" => "application/magic-envelope+xml"})
  end

  # Send an update to a remote user as a Salmon notification
  def send_mention_notification(update_id, to_feed_id)
    f = Feed.first :id => to_feed_id
    u = Update.first :id => update_id

    protocol = author.use_ssl ? "https" : "http"
    base_uri = "#{protocol}://#{author.domain}/"
    salmon = OStatus::Salmon.new(u.to_atom(base_uri))

    envelope = salmon.to_xml self.to_rsa_keypair

    # Send envelope to Author's Salmon endpoint
    uri = URI.parse(f.author.salmon_url)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == "https"
      http.use_ssl = (uri.port == 443)
    end
    res = http.post(uri.path, envelope, {"Content-Type" => "application/magic-envelope+xml"})
  end

  def autocomplete(query)
    if query.nil? || query.blank?
      return []
    end

    query = '^' + Regexp.escape(query) + '.*'
    following.inject([]) do |result, obj|
      if /#{query}/i =~ obj.author.fully_qualified_name
        result << { :label => obj.author.fully_qualified_name.downcase }
      end
      result
    end
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
    if existing_feeds.empty? and feed_url.match(/^http[s]?:\/\/#{author.domain}\//)
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
  def timeline
    following_plus_me = following.map(&:author_id)
    following_plus_me << self.author.id
    Update.where(:author_id => following_plus_me).order(['created_at', 'descending'])
  end

  # Retrieve the list of Updates that are replies to this user
  def at_replies
    Update.where(:text => /^@#{Regexp.quote(username)}\b/).order(['created_at', 'descending'])
  end

  # User MUST be confirmed
  key :status

  # Users have a password
  key :hashed_password, String

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
    reset_perishable_token
  end

  # Authenticate the user by checking their credentials
  def self.authenticate(username, pass)
    user = User.find_by_case_insensitive_username(username)
    return nil if user.nil?
    return nil unless user.hashed_password
    return user if BCrypt::Password.new(user.hashed_password) == pass
    nil
  end

  # Edit profile information
  def update_profile!(params)

    params[:email] = nil if params[:email].blank?

    self.username               = params[:username]

    self.email_confirmed        = self.email == params[:email]
    self.email                  = params[:email]

    self.always_send_to_twitter = params[:user] && params[:user][:always_send_to_twitter].to_i

    # I can't figure out how to use a real rails validator to confirm that
    # password matches password_confirm, since these two attributes are
    # virtual and we only want to check this in this particular case of
    # updating a user.

    # Additionally, running the other validations clears self.errors, so
    # we need to add our own errors AFTER calling valid?. But we shouldn't
    # save the record at all if the password change isn't valid.

    self.valid?

    unless params[:password].blank?
      if params[:password] == params[:password_confirm]
        self.password = params[:password]
        self.save
      else
        self.errors.add(:password, "doesn't match confirmation.")
      end
    end

    # Calling valid? again here would make the validators run again, which
    # would clear self.errors again. We may have added an error about the
    # password not matching the confirmation.
    if self.errors.present?
      return false
    else
      self.save

      author.username = params[:username]
      author.name     = params[:name]
      author.email    = params[:email]
      author.website  = params[:website]
      author.bio      = params[:bio]
      author.save

      # TODO: Send out notice to other nodes
      # To each remote domain that is following you via hub
      # and to each remote domain that you follow via salmon
      author.feed.ping_hubs

      return self
    end
  end

  # A better name would be very welcome.
  def self.find_by_case_insensitive_username(username)
    username = Regexp.escape(username)
    User.first(:username => /^#{username}$/i)
  end

  def token_expired?
    self.perishable_token_set.to_time < 2.days.ago
  end

  def to_param
    username
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
    return if self.email.blank?
    if User.where(:email => self.email,
                  :email_confirmed => true,
                  :id.ne => self.id).count > 0
      errors.add(:email, "is already taken.")
    end
  end
end
