class AuthorDecorator < ApplicationDecorator
  decorates :author

  def website_link
    url = if model.website[0,7] == "http://" or model.website[0,8] == "https://"
            model.website
          else
            "http://#{model.website}"
          end

    h.link_to(url, url, :rel => 'me', :class => 'url')
  end
end
