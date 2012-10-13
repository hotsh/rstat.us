module MenuHelper
  def menu_item(name, url, options = {})
    icon    = options.fetch(:icon)    { false }
    classes = options.fetch(:classes) { [] }
    rel     = options.fetch(:rel)     { nil }

    classes << name.downcase.gsub(' ', '_')
    classes << 'active' if request.path_info == url

    content_tag 'li', class: classes do
      link_to url, rel: rel do
        (icon ? content_tag('div', '', class: 'icon') : '') + name
      end
    end
  end
end
