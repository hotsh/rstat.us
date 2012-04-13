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
end