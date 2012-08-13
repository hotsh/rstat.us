# An Authorization represents a connection to someone's social media profile.
class Authorization
  include MongoMapper::Document

  # If you don't hook up an Authorization to a User... you're not making much
  # sense.
  belongs_to :user
  key :user_id, ObjectId

  key :uid,          Integer, required: true
  key :provider,     String,  required: true
  key :oauth_token,  String
  key :oauth_secret, String
  key :nickname

  # Super cool validations. We don't want to let two people sign up with the
  # same external auth, but just in case there's a clash between providers,
  # we scope it. So easy!
  validates_uniqueness_of :uid, scope: :provider

  # Locates an authorization from data provided from a successful omniauth
  # authentication response
  def self.find_from_hash(hash)

    # Pull out the details
    uid      = hash['uid'].to_i
    provider = hash['provider']

    # Find the first record from the details
    first provider: provider, uid: uid
  end

  def self.create_from_session!(session, user)
    # Create a new authorization with the provided details
    create!(
      user:         user,
      uid:          session[:uid],
      provider:     session[:provider],
      nickname:     session[:nickname],
      oauth_token:  session[:oauth_token],
      oauth_secret: session[:oauth_secret]
    )
  end

  # Creates an authorization from a sucessful omniauth authentication response
  def self.create_from_hash!(hash, base_uri, user = nil)

    # If there isn't a user, create a user and author.
    if user.nil?
      author = Author.create_from_hash!(hsh, base_uri)
      user   = User.create(
                 :author   => author,
                 :username => author.username
               )
    end

    # Grab the user information from the hash
    uid, provider, nickname = hash['uid'], hash['provider'], hash['info']['nickname']

    # Grab the credentials, including token and secret, from the hash
    credentials = hash['credentials']
    token, secret = credentials['token'], credentials['secret']

    # Create a new authorization with the provided details
    create!(
      user: user,
      uid: uid,
      provider: provider,
      nickname: nickname,
      oauth_token: token,
      oauth_secret: secret
    )
  end

  timestamps!

end
