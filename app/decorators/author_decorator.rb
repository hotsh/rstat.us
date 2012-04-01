class AuthorDecorator < ApplicationDecorator
  decorates :author

  def avatar
    h.content_tag "div", :class => "avatar" do
      h.link_to(
        h.image_tag(avatar_src, :class => "photo", :alt => "avatar"),
        author.url
      )
    end
  end

  def website_link
    url = if model.website[0,7] == "http://" or model.website[0,8] == "https://"
            model.website
          else
            "http://#{model.website}"
          end

    h.link_to(url, url, :rel => 'me', :class => 'url')
  end

  private

  def avatar_src
    if author.avatar_url.eql? Author::DEFAULT_AVATAR
      h.asset_path(author.avatar_url)
    else
      author.avatar_url
    end
  end
end
