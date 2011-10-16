module ApplicationHelper
  def avatar_for(author)
    if author.avatar_url.eql? Author::DEFAULT_AVATAR
      asset_path(author.avatar_url)
    else
      author.avatar_url
    end
  end
end
