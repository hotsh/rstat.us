# The Author model represents someone who creates information that's
# shared via a feed. It is decoupled from a User, since we can also have
# remote authors, from feeds that originate from outside of our site.

class Author
  include MongoMapper::Document

  # Constants that are useful for avatars using gravatar
  GRAVATAR               = "gravatar.com"
  GRAVATAR_SIGNUP        = "http://gravatar.com/site/signup"
  ENCODED_DEFAULT_AVATAR = URI.encode_www_form_component(
                             RstatUs::DEFAULT_AVATAR
                           )

  # public keys are good for 4 weeks
  PUBLIC_KEY_LEASE_DAYS = 28

  # Schema

  # We've got a bunch of data that gets stored in Author. And basically none
  # of it is validated right now. Fun. Then again, not all of it is neccesary.
  key :username,  String

  # This contains the domain that the author's feed originates.
  key :domain,    String

  # When true, this author wishes ssl and https to be used for their endpoints
  key :use_ssl,   Boolean

  # The Author has a profile and with that various entries
  key :name,      String
  key :email,     String
  key :website,   String
  key :bio,       String
  key :image_url, String

  # Authors MIGHT have a salmon endpoint
  key :salmon_url, String

  # Authors have a public key that they use to sign salmon responses.
  #  Leasing: To ensure that keys can only be compromised in a small window but
  #  not require the server to retrieve a key per update, we store a lease.
  #  When the lease expires, and a notification comes, we retrieve the key.
  key :public_key, String
  key :public_key_lease, Date

  # The url of their profile page
  key :remote_url, String

  # For sorting by signup, Authors require timestamps
  timestamps!

  # Validations

  validates_presence_of :domain
  # We cannot put a :unique tag above because of a MongoMapper bug
  validates_uniqueness_of :remote_url, :allow_nil => :true

  # Associations

  # As we said, an Author has a Feed that they're the... author of. And if
  # they're local, they also have a User.
  one :feed, :dependent => :destroy
  one :user

  # Callbacks

  # Normalize the domain so we can use them the same way
  before_save :normalize_domain

  # Make sure the image url uses https
  before_save :https_image_url

  # Twitter has an SSL cert that doesn't match the domain but we can
  # change the domain to match the cert and the avatars work
  before_save :modify_twitter_image_url_domain

  # This takes results from an omniauth reponse and generates an author
  def self.create_from_hash!(hash, domain)
    # Omniauth user information, as a hash
    user  = hash['info']

    # Grabs each of the important user details
    name       = user['name']
    username   = user['username']
    website    = user['urls']['Website']
    bio        = user['description']
    image_url  = user['image']
    remote     = user['url']

    # Creates an Author object with the details
    create!(
      name:       name,
      username:   username,
      website:    website,
      bio:        bio,
      image_url:  image_url,
      remote_url: remote,
      domain:     domain
    )
  end

  def self.new_from_session!(session, params, domain)
    new(
      :name      => session[:name],
      :username  => params[:username],
      :website   => session[:website],
      :bio       => session[:description],
      :image_url => session[:image],
      :domain    => domain
    )
  end

  def self.create_from_session!(session, params, domain)
    create!(
      :name      => session[:name],
      :username  => params[:username],
      :website   => session[:website],
      :bio       => session[:description],
      :image_url => session[:image],
      :domain    => domain
    )
  end

  # Reset the public key lease, which will be called when the public key is
  # retrieved from a trusted source.
  def reset_key_lease
    public_key_lease = (DateTime.now + PUBLIC_KEY_LEASE_DAYS).to_date
  end

  # Retrieves a valid RSA::KeyPair for the Author's public key
  def retrieve_public_key
    Crypto.make_rsa_keypair(public_key, nil)
  end

  def check_public_key_lease
    if public_key_lease.nil? or public_key_lease < DateTime.now
      # Lease has expired, get the public key again

      # Retrieve the user xrd
      remote_host = remote_url[/^.*?:\/\/(.*?)\//,1]
      webfinger   = "#{username}@#{remote_host}"
      acct        = Redfinger.finger(webfinger)

      # Retrieve the public key
      public_key = acct.links.find { |l| l['rel'] == 'magic-public-key' }
      public_key = public_key.href[/^.*?,(.*)$/,1]
      self.public_key = public_key
      reset_key_lease

      unless new?
        save!
      end
    end
  end

  # Returns a locally useful url for the Author
  def url
    if remote?
      remote_url
    else
      "/users/#{username}"
    end
  end

  def fully_qualified_name
    if remote?
      "#{username}@#{domain}"
    else
      "#{username}"
    end
  end

  def remote?
    remote_url.present?
  end

  # Returns a locally useful url for the Author's avatar

  # We've got a couple of options here. If they have some sort of image from
  # Twitter, we use that, and if they don't, we go with Gravatar.
  # If none of that is around, then we show the RstatUs::DEFAULT_AVATAR
  def avatar_url

    # If the user has a twitter image, return it
    if image_url.present?
      image_url

    # If the user has an email, look for a gravatar url.
    elsif email.present?
      gravatar_url

    # Otherwise return the default avatar
    else
      RstatUs::DEFAULT_AVATAR
    end
  end

  # Determine the display name from the username or name
  def display_name

    # If the user has a name, return it
    if name.present?
      name

    # Otherwise return the username
    else
      username
    end
  end

  # Return the gravatar url
  # Query described [here](http://en.gravatar.com/site/implement/images/#default-image).
  def gravatar_url
    email_digest = Digest::MD5.hexdigest email
    "https://#{GRAVATAR}/avatar/#{email_digest}?s=48&r=r&d=#{ENCODED_DEFAULT_AVATAR}"
  end

  # Returns an OStatus::Author instance describing this author model
  def to_atom

    # Determine global url for this author
    author_url = url
    if author_url.start_with?("/")
      author_url = "http://#{domain}/feeds/#{feed.id}"
    end

    # Set up PortableContacts
    poco = OStatus::PortableContacts.new(:id => author_url,
                                         :preferred_username => username)
    poco.display_name = display_name

    # Set up and return Author
    avatar_url_abs = avatar_url
    if avatar_url_abs.start_with?("/")
      avatar_url_abs = "http://#{domain}#{avatar_url_abs}"
    end

    author = OStatus::Author.new(:name => username,
               :uri => author_url,
               :portable_contacts => poco,
               :links => [Atom::Link.new(:rel => "avatar",
                                         :type => "image/png",
                                         :href => avatar_url_abs)])
    author
  end

  def normalize_domain
    set_default_use_ssl if use_ssl.nil?

    norm = self.domain
    norm = norm.gsub(/^.*:\/\//, "")  # remove protocol
    norm = norm.gsub(/^www./, "")     # remove www
    norm = norm.gsub(/\/.*$/, "")     # remove trailing slash
    norm = norm.gsub(/\?.*$/, "")     # remove query string
    norm = norm.gsub(/#.*$/, "")      # remove anchors

    self.domain = norm
  end

  def https_image_url
    self.image_url.sub!(/^http:/, 'https:') if self.image_url.present?
  end

  def modify_twitter_image_url_domain
    self.image_url.sub!(/a\d.twimg.com/, "twimg0-a.akamaihd.net") if self.image_url.present?
  end

  def to_param
    username
  end

  def self.search(params = {})
    if params[:search] && !params[:search].empty?
      Author.where(:username => /#{params[:search]}/i)
    else
      []
    end
  end

  def set_default_use_ssl
    self.use_ssl = self.domain.start_with?("https")
  end
end
