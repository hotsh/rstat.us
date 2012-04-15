# This is a small convenience class that wraps an OStatus::Author so that
# other classes don't have to know about the internal structure of an
# OStatus::Author to get these attributes out.

class SalmonAuthor
  def initialize(salmon_author)
    @author = salmon_author
  end

  def uri
    @author.uri
  end

  def name
    @author.portable_contacts.display_name
  end

  def username
    @author.name
  end

  def bio
    @author.portable_contacts.note
  end

  def avatar_url
    @author.links.find_all{|l| l.rel.downcase == "avatar"}.first.href
  end

  def email
    email = @author.email

    if email == ""
      return nil
    end
    email
  end

  def author_attributes
    {
      :name       => name,
      :username   => username,
      :remote_url => uri,
      :domain     => uri,
      :email      => email,
      :bio        => bio,
      :image_url  => avatar_url
    }
  end

  def ==(other)
    if self.class == other.class
      # Compare SalmonAuthors on their uris since that's how we
      # uniquely identify SalmonAuthors. This isn't actually used
      # anywhere except in the salmon_author_test.
      return uri == other.uri
    else
      # Treat the other object like an Author if it quacks like an Author!
      # Compare on the attributes that are equivalent.
      return uri == other.remote_url &&
             name == other.name &&
             username == other.username &&
             email == other.email &&
             bio == other.bio &&
             avatar_url == other.image_url
    end
  end
end