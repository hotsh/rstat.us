class User
  require 'digest/md5'

  include MongoMapper::Document
  many :authorizations, :dependant => :destroy

  key :username, String, :required => true
  key :perishable_token, String

  key :email, String #, :unique => true, :allow_nil => true

  # eff you mongo_mapper.
  validates_uniqueness_of :email, :allow_nil => :true 
  validates_uniqueness_of :username, :allow_nil => :true 

  # validate users don't have @ in their usernames
  validate :no_special_chars

  belongs_to :author
  belongs_to :feed

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

  def url
    feed.local? ? "/users/#{feed.author.username}" : feed.author.url
  end
  

  def twitter?
    has_authorization?(:twitter)
  end
  
  def twitter
    get_authorization(:twitter)
  end
  
  def facebook?
    has_authorization?(:facebook)
  end
  
  def facebook
    get_authorization(:facebook)
  end
  
  # Check if a a user has a certain authorization by providing the assoaciated
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

  key :following_ids, Array
  many :following, :in => :following_ids, :class_name => 'Feed'

  key :followers_ids, Array
  many :followers, :in => :followers_ids, :class_name => 'Feed'

  # follow takes a url
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

  def timeline(params)
    popts = {
      :page => params[:page],
      :per_page => params[:per_page]
    }

    following_plus_me = following.clone
    following_plus_me << self.feed
    Update.where(:author_id => following_plus_me.map(&:author_id)).order(['created_at', 'descending']).paginate(popts)
  end

  def at_replies(params)
    popts = {
      :page => params[:page],
      :per_page => params[:per_page]
    }
    Update.where(:text => /^@#{username}\b/).order(['created_at', 'descending']).paginate(popts)
  end

  key :status

  attr_accessor :password
  key :hashed_password, String
  key :password_reset_sent, DateTime, :default => nil

  def password=(pass)
    @password = pass
    self.hashed_password = BCrypt::Password.create(@password, :cost => 10)
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

  def self.authenticate(username, pass)
    user = User.first(:username => username)
    return nil if user.nil?
    return user if BCrypt::Password.new(user.hashed_password) == pass
    nil
  end

  def reset_username(params)
    self.username = params[:username]
    author.username = params[:username]
    return false unless save
    author.save
  end

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

  # validation that checks @s in usernames
  def no_special_chars
    unless (username =~ /[@!"#$\%&'()*,^~{}|`=:;\\\/\[\]?]/).nil? && (username =~ /^[.]/).nil? && (username =~ /[.]$/).nil? && (username =~ /[.]{2,}/).nil?
      errors.add(:username, "contains restricted characters.")
    end
  end
end
