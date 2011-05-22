# An Authorization represents a connection to someone's social media profile.
# For example, a User might have two Authorizations, one for their Twitter
# and one for their Facebook.

class Authorization
  include MongoMapper::Document

  # If you don't hook up an Authorization to a User... you're not making much
  # sense.
  belongs_to :user

  key :uid,          Integer, :required => true
  key :provider,     String,  :required => true
  key :oauth_token,  String
  key :oauth_secret, String
  key :nickname

  # Super cool validations. We don't want to let two people sign up with the
  # same external auth, but just in case there's a clash between providers,
  # we scope it. So easy!
  validates_uniqueness_of :uid, :scope => :provider

  # Locates an authorization from data provided from a successful omniauth
  # authentication response
  def self.find_from_hash(hash)

    # Pull out the details
    uid      = hash['uid'].to_i
    provider = hash['provider']

    # Find the first record from the details
    first provider: provider, uid: uid
  end

  # Creates an authorization from a sucessful omniauth authentication response
  def self.create_from_hash(hash, base_uri, user = nil)
    if user.blank?
      author = Author.create_from_hash! hash

      user = User.create! author: author, username: author.username
    end

    uid = hash['uid']
    provider = hash['provider']
    nickname = hash['user_info']['nickname']
    token = hash['credentials']['token']
    secret = hash['credentials']['secret']

    create!(
        user:         user,
        uid:          uid,
        provider:     provider,
        nickname:     nickname,
        oauth_token:  token,
        oauth_secret: secret
      )
  end

  timestamps!

end
