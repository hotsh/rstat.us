class Author
  include MongoMapper::Document
  
  key :username, String
  key :name, String
  key :email, String
  key :website, String
  key :bio, String
  key :image_url, String

  one :feed
  one :user

 # The url of their profile page
  key :url, String

  def self.create_from_hash!(hsh)
    create!(
      :name => hsh['user_info']['name'],
      :username => hsh['user_info']['nickname'],
      :website => hsh['user_info']['urls']['Website'],
      :bio => hsh['user_info']['description'],
      :image_url => hsh['user_info']['image'],
      :url => hsh['user_info']['url']
    )
  end

  def avatar_url
    if image_url.nil?
      if email.nil?
        # Using a default avatar
        "/images/avatar.png"
      else
        # Using gravatar
        "http://gravatar.com/avatar/" + Digest::MD5.hexdigest(email) + "?s=48"
      end
    else
      # Use the twitter image
      image_url
    end
  end

end


