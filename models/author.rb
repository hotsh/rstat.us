class Author
  include MongoMapper::Document

  # Constants that are useful for avatars using gravatar
  DEFAULT_AVATAR = "/images/avatar.png"
  ENCODED_DEFAULT_AVATAR = URI.encode_www_form_component(DEFAULT_AVATAR)
  GRAVATAR_HOST  = "gravatar.com"
  
  # Authors have some identifying information
  key :username, String
  key :name, String
  key :email, String
  key :website, String
  key :bio, String
  key :image_url, String

  # Authors MIGHT have a salmon endpoint
  key :salmon_url, String
  
  # The url of their profile page
  key :remote_url, String

  # We cannot put a :unique tag above because of a MongoMapper bug
  validates_uniqueness_of :remote_url, :allow_nil => :true 

  # Associations
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

  # Returns a locally useful url for the Author
  def url
    return remote_url if remote_url
    "/users/#{username}"
  end

  # Returns a locally useful url for the Author's avatar
  def avatar_url
    return image_url      if image_url
    return DEFAULT_AVATAR if email.nil?

    # if the gravatar doesn't exist, gravatar will use a default that we provide
    gravatar_url
  end

  # Returns a url useful for gravatar support
  def gravatar_url
    "http://#{GRAVATAR_HOST}#{self.gravatar_path}"
  end

  # these query parameters are described at:
  #   <http://en.gravatar.com/site/implement/images/#default-image>
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
