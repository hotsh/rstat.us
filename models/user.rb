# The User model contains all of the information that a particular user of our
# site needs: their username/password, etc. It all comes from here. Even users
# that sign up via Twitter get a User model, though it's a bit empty in that
# particular case.

class User
  require 'digest/md5'
  require 'openssl'
  require 'rsa'

  include MongoMapper::Document

  # Associations
  many :authorizations, :dependant => :destroy
  belongs_to :author

  # Users MUST have a username
  key :username, String, :required => true

  # Users MIGHT have an email
  key :email, String

  # RSA for salmon usage
  key :private_key, String

  # Required for confirmation
  key :perishable_token, String

  # We cannot put a :unique tag above because of a MongoMapper bug
  validates_uniqueness_of :email, :allow_nil => :true
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

  # Before a user is created, we will generate some RSA keys
  def generate_rsa_pair
    key = RSA::KeyPair.generate(2048)

    public_key = key.public_key
    m = public_key.modulus
    e = public_key.exponent

    modulus = ""
    until m == 0 do
      modulus << [m % 256].pack("C")
      m >>= 8
    end
    modulus.reverse!

    exponent = ""
    until e == 0 do
      exponent << [e % 256].pack("C")
      e >>= 8
    end
    exponent.reverse!

    public_key = "RSA.#{Base64::urlsafe_encode64(modulus)}.#{Base64::urlsafe_encode64(exponent)}"

    tmp_private_key = key.private_key
    m = tmp_private_key.modulus
    e = tmp_private_key.exponent

    modulus = ""
    until m == 0 do
      modulus << [m % 256].pack("C")
      m >>= 8
    end
    modulus.reverse!

    exponent = ""
    until e == 0 do
      exponent << [e % 256].pack("C")
      e >>= 8
    end
    exponent.reverse!

    tmp_private_key = "RSA.#{Base64::urlsafe_encode64(modulus)}.#{Base64::urlsafe_encode64(exponent)}"

    self.author.public_key = public_key
    self.author.save

    self.private_key = tmp_private_key
  end

  # Retrieves a valid RSA::KeyPair for the User's private key
  def retrieve_private_key
    # Create the private key from the key stored

    # Retrieve the exponent and modulus from the key string
    private_key.match /^RSA\.(.*?)\.(.*)$/
    modulus = Base64::urlsafe_decode64($1)
    exponent = Base64::urlsafe_decode64($2)

    modulus = modulus.bytes.inject(0) {|num, byte| (num << 8) | byte }
    exponent = exponent.bytes.inject(0) { |num, byte| (num << 8) | byte }

    # Create the public key instance
    key = RSA::Key.new(modulus, exponent)
    keypair = RSA::KeyPair.new(key, nil)
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

  # Returns true when this user has a facebook authorization
  def facebook?
    has_authorization?(:facebook)
  end

  # Returns the facebook authorization
  def facebook
    get_authorization(:facebook)
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

  # The User is being followed by this feed
  def followed_by! feed
    followers << feed
    save
  end

  def unfollowed_by! feed
    followers_ids.delete(feed.id)
    save
  end

  # Follow a particular feed
  def follow! feed_url, xrd = nil
    f = Feed.first(:url => feed_url)

    # local feed?
    if f.nil? and feed_url.start_with?("/")
      feed_id = feed_url[/^\/feeds\/(.+)$/,1]
      f = Feed.first(:id => feed_id)
    end

    # can't follow yourself
    if f == self.feed
      return
    end

    if f.nil?
      f = Feed.create(:remote_url => feed_url)

      # Populate the Feed with Updates and Author from the remote site
      # Pass along the xrd information to build the Author if available
      f.populate xrd
    end

    following << f
    save

    if f.local?
      followee = User.first(:author_id => f.author.id)
      followee.followed_by! self.feed
      followee.save
    else
      # Send Salmon notification so that the remote user
      # knows this user is following them
      salmon = OStatus::Salmon.from_follow(author.to_atom, f.author.to_atom)

      envelope = salmon.to_xml retrieve_private_key

      # Send envelope to Author's Salmon endpoint
      #puts "Sending salmon slap to #{f.author.salmon_url}"
      uri = URI.parse(f.author.salmon_url)
      http = Net::HTTP.new(uri.host, uri.port)
      res = http.post(uri.path, envelope, {"Content-Type" => "application/magic-envelope+xml"})
      #puts res
      #p res
    end

    f
  end

  # unfollow takes a feed (since it is guaranteed to exist)
  def unfollow! followed_feed
    following_ids.delete(followed_feed.id)
    save
    if followed_feed.local?
      followee = User.first(:author_id => followed_feed.author.id)
      followee.unfollowed_by!(self.feed)
    else
      # Send Salmon notification so that the remote user
      # knows this user has stopped following them
      salmon = OStatus::Salmon.from_unfollow(author.to_atom, f.author.to_atom)

      envelope = salmon.to_xml retrieve_private_key

      # Send envelope to Author's Salmon endpoint
      uri = URI.parse(f.author.salmon_url)
      res = Net::HTTP.start(uri.host, uri.port) do |http|
        http.post(uri.path, envelope)
      end
    end
  end

  def followed_by? feed_url
    f = Feed.first(:remote_url => feed_url)
    p "followed_by"
    p f

    # local feed?
    if f.nil? and feed_url.start_with?("/")
      feed_id = feed_url[/^\/feeds\/(.+)$/,1]
      f = Feed.first(:id => feed_id)
    end

    if f.nil?
      false
    else
      followers.include? f
    end
  end

  def following? feed_url
    f = Feed.first(:remote_url => feed_url)

    # local feed?
    if f.nil? and feed_url.start_with?("/")
      feed_id = feed_url[/^\/feeds\/(.+)$/,1]
      f = Feed.first(:id => feed_id)
    end

    if f.nil?
      false
    else
      following.include? f
    end
  end

  timestamps!

  # Retrieve the list of Updates in the user's timeline
  def timeline(params)
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
  key :password_reset_sent, DateTime, :default => nil

  # Store the hash of the password
  def password=(pass)
    self.hashed_password = BCrypt::Password.create(pass, :cost => 10)
  end

  # Create a new perishable token and set the date the password reset token was
  # sent so tokens can be expired after 2 days
  def set_password_reset_token
    self.password_reset_sent = DateTime.now
    set_perishable_token
    self.perishable_token
  end

  # Set a new password, clear the date the password reset token was sent and
  # reset the perishable token
  def reset_password(pass)
    self.password = pass
    self.password_reset_sent = nil
    reset_perishable_token
  end

  # Authenticate the user by checking their credentials
  def self.authenticate(username, pass)
    user = User.first(:username => username)
    return nil if user.nil?
    return user if BCrypt::Password.new(user.hashed_password) == pass
    nil
  end

  # Reset the username to one given
  def reset_username(params)
    self.username = params[:username]
    author.username = params[:username]
    return false unless save
    author.save
  end

  # Edit profile information
  def edit_user_profile(params)
    author.name    = params[:name]
    author.email   = params[:email]
    author.website = params[:website]
    author.bio     = params[:bio]
    author.save
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
end
