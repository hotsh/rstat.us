class User
  require 'digest/md5'

  include MongoMapper::Document

  # Associations
  many :authorizations, :dependant => :destroy
  belongs_to :author
  belongs_to :feed

  # Users MUST have a username
  key :username, String, :required => true

  # Users MIGHT have an email
  key :email, String

  # Required for confirmation
  key :perishable_token, String

  # We cannot put a :unique tag above because of a MongoMapper bug
  validates_uniqueness_of :email, :allow_nil => :true 
  validates_uniqueness_of :username, :allow_nil => :true 
  
  # The maximum is arbitrary
  validates_length_of :username, :minimum => 1, :maximum => 16
  
  # Validate users don't have special characters in their username
  validate :username_wellformed
  
  # This will establish other entities related to the User
  after_create :finalize

  # After a user is created, create the feed and reset the token
  def finalize
    create_feed
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
  
  # Check if a user has a certain authorization by providing the associated
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

  # Follow a particular feed
  def follow! feed_url
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
      f.populate
    end

    following << f
    save

    if f.local?
      followee = User.first(:author_id => f.author.id)
      followee.followers << self.feed
      followee.save
    end

    f
  end

  # unfollow takes a feed (since it is guaranteed to exist)
  def unfollow! followed_feed
    following_ids.delete(followed_feed.id)
    save
    if followed_feed.local?
      followee = User.first(:author_id => followed_feed.author.id)
      followee.followers_ids.delete(self.feed.id)
      followee.save
    end
  end

  def following? feed_url
    f = Feed.first(:remote_url => feed_url)

    # local feed?
    if f.nil? and feed_url[0].chr == "/"
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
    popts = {
      :page => params[:page],
      :per_page => params[:per_page]
    }

    following_plus_me = following.clone
    following_plus_me << self.feed
    Update.where(:author_id => following_plus_me.map(&:author_id)).order(['created_at', 'descending']).paginate(popts)
  end

  # Retrieve the list of Updates that are replies to this user
  def at_replies(params)
    popts = {
      :page => params[:page],
      :per_page => params[:per_page]
    }
    Update.where(:text => /^@#{username}\b/).order(['created_at', 'descending']).paginate(popts)
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

  def create_feed()
    self.author = Author.create :name => "", :username => username if author.nil?
    f = Feed.create(
      :author => author
    )

    self.feed = f
    save
  end

  # Validation that checks for invalid usernames
  def username_wellformed
    unless (username =~ /[@!"#$\%&'()*,^~{}|`=:;\\\/\[\]?]/).nil? && (username =~ /^[.]/).nil? && (username =~ /[.]$/).nil? && (username =~ /[.]{2,}/).nil?
      errors.add(:username, "contains restricted characters.")
    end
  end
end
