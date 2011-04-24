# The Author model represents someone who creates information that's
# shared via a feed. It is decoupled from a User, since we can also have
# remote authors, from feeds that originate from outside of our site.

class Author
  include MongoMapper::Document

  # Constants that are useful for avatars using gravatar
  DEFAULT_AVATAR = "/images/avatar.png"
  ENCODED_DEFAULT_AVATAR = URI.encode_www_form_component(DEFAULT_AVATAR)
  GRAVATAR_HOST  = "gravatar.com"

  # We've got a bunch of data that gets stored in Author. And basically none
  # of it is validated right now. Fun. Then again, not all of it is neccesary.
  key :username, String

  # This contains the domain that the author's feed originates (nil for local)
  key :domain, String

  # We can get the domain from the remote_url
  before_save :get_domain 

  # The Author has a profile and with that various entries
  key :name, String
  key :email, String
  key :website, String
  key :bio, String
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

  # We cannot put a :unique tag above because of a MongoMapper bug
  validates_uniqueness_of :remote_url, :allow_nil => :true 

  # Associations

  # As we said, an Author has a Feed that they're the... author of. And if
  # they're local, they also have a User, too.
  one :feed
  one :user
  
  # This takes results from an omniauth reponse and generates an author
  def self.create_from_hash!(hsh)
    create!(
      :name => hsh['user_info']['name'],
      :username => hsh['user_info']['nickname'],
      :website => hsh['user_info']['urls']['Website'],
      :bio => hsh['user_info']['description'],
      :image_url => hsh['user_info']['image'],
      :remote_url => hsh['user_info']['url']
    )
  end

  # Reset the public key lease, which will be called when the public key is
  # retrieved from a trusted source.
  def reset_key_lease
    # public keys are good for 4 weeks
    public_key_lease = (DateTime.now + 28).to_date
  end

  # Returns a locally useful url for the Author
  def url
    return remote_url if remote_url
    "/users/#{username}"
  end

  # Returns a locally useful url for the Author's avatar

  # We've got a couple of options here. If they have some sort of image from
  # Facebook or Twitter, we use that, and if they don't, we go with Gravatar.
  # If none of that is around, then we show the DEFAULT_AVATAR
  def avatar_url
    return image_url      if image_url
    return DEFAULT_AVATAR if email.nil?

    gravatar_url
  end

  def get_domain
    if self.remote_url
      self.domain = remote_url[/\:\/\/(.*?)\//, 1]
    end
  end

  # Returns a url useful for gravatar support
  def gravatar_url
    "http://#{GRAVATAR_HOST}#{gravatar_path}"
  end

  # these query parameters are described [here](http://en.gravatar.com/site/implement/images/#default-image).
  def gravatar_path
    "/avatar/#{Digest::MD5.hexdigest(email)}?s=48&r=r&d=#{ENCODED_DEFAULT_AVATAR}"
  end

  # Returns the display name to be used for the Author.
  def display_name
    return username if name.nil? || name.empty?
    name
  end

  # Returns an OStatus::Author instance describing this author model
  # Must give it a base_uri
  def to_atom(base_uri)

    # Determine global url for this author
    author_url = url
    if author_url.start_with?("/")
      author_url = base_uri + author_url[1..-1]
    end

    # Set up PortableContacts
    poco = OStatus::PortableContacts.new(:id => author_url,
                                         :preferred_username => username)
    poco.display_name = name unless name.nil? || name.empty?

    # Set up and return Author
    avatar_url_abs = avatar_url
    if avatar_url_abs.start_with?("/")
      avatar_url_abs = "#{base_uri}#{avatar_url[1..-1]}"
    end

    author = OStatus::Author.new(:name => username,
               :uri => author_url,
               :portable_contacts => poco,
               :links => [Atom::Link.new(:rel => "avatar",
                                        :type => "image/png",
                                        :href => avatar_url_abs)])

    author.email = email unless email.nil?

    author
  end
end
