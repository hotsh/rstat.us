class Authorization
  include MongoMapper::Document

  belongs_to :user

  key :uid, Integer, :required => true
  key :provider, String, :required => true
  key :oauth_token, String
  key :oauth_secret, String
  key :nickname

  validates_uniqueness_of :uid, :scope => :provider

  def self.find_from_hash(hsh)
    first :provider => hsh['provider'], :uid => hsh['uid'].to_i
  end

  def self.create_from_hash(hsh, base_uri, user = nil)
    if user.nil?
      author = Author.create_from_hash!(hsh)
      user = User.create(:author => author,
                         :username => author.username
                        )
    end

    a = new(:user => user, 
            :uid => hsh['uid'], 
            :provider => hsh['provider'],
            :nickname => hsh["user_info"]["nickname"],
            :oauth_token => hsh['credentials']['token'],
            :oauth_secret => hsh['credentials']['secret']
           )

    a.save
    a.errors.each{|e| puts e.inspect }
    a
  end

  timestamps!

end
