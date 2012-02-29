class Webfinger
  def self.find_user(webfinger_name)
    # Webfinger likes to give fully qualified names.
    # For example: "acct:wilkie@rstat.us"
    # We are going to relax this format and look up usernames whether or not
    # the name starts with acct: and whether or not it ends with @domain

    # This regex has essentially three parts:
    # ([^@\:]+\:)? = the optional prefix that ends with a colon
    # ([^@\:]*?)   = the username
    # (@[^@\:]+)?  = the optional domain that starts with an @

    username = webfinger_name[/^([^@\:]+\:)?([^@\:]*?)(@[^@\:]+)?$/, 2] || webfinger_name

    User.first :username => /^#{username}$/i
  end
end