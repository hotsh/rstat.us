class Authorization
  include MongoMapper::Document

  belongs_to :user

  key :uid, Integer, :required => true
  key :provider, String, :required => true

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
      user.finalize(base_uri)
    end

    a = new(:user => user, 
            :uid => hsh['uid'], 
            :provider => hsh['provider']
           )

    a.save
    a.errors.each{|e| puts e.inspect }
    a
  end

  timestamps!

end
