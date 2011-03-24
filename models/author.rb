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
  key :remote_url, String

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

  def url
    if remote_url.nil?
      "/users/#{username}"
    else
      remote_url
    end
  end

  def avatar_url
    if image_url.nil?
      if email.nil?
        # Using a default avatar
        "/images/avatar.png"
      else
        # Using gravatar
        current_url = "http://gravatar.com/avatar/" + Digest::MD5.hexdigest(email) + "?s=48&r=r&d=404"
        res = Net::HTTP.get_response(URI.parse(current_url))
        if res.class == Net::HTTPNotFound
          "/images/avatar.png"
        else
          current_url
        end
      end
    else
      # Use the twitter image
      image_url
    end
  end

end


