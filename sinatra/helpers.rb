module Sinatra
  module UserHelper


    # Many pages on rstatus are paginated. To keep track of it in all the
    # different routes we have this handy helper that either picks up
    # the previous setting or resets it to a default value.
    def set_params_page
      params[:page] = params.fetch("page"){1}.to_i
      params[:per_page] = params.fetch("per_page"){20}.to_i
    end

    # Similar to the set_params_page helper this one creates the links
    # for the previous and the next page on all routes that display
    # stuff on more than one page.
    #If needed it can also take options for more parameters
    def set_pagination_buttons(data, options = {})
      return if data.nil? || data.empty?

      if data.next_page
        params = {
                   :page     => data.next_page,
                   :per_page => data.per_page
                 }.merge(options)

        @next_page = "?#{Rack::Utils.build_query params}"
      end

      if data.previous_page
        params = {
                   :page     => data.previous_page,
                   :per_page => data.per_page
                 }.merge(options)

        @prev_page = "?#{Rack::Utils.build_query params}"
      end
    end
  end

  module ViewHelper
    def pluralize(count, singular, plural = nil)
      "#{count || 0} " + ((count == 1 || count =~ /^1(\.0+)?$/) ? singular : (plural || singular.pluralize))
    end

    def title(str)
      @title = str
      pjax_request? ? @title : nil
    end

    def pjax_request?
      env['HTTP_X_PJAX']
    end

    def show_layout?
      !pjax_request?
    end

  end

  helpers UserHelper
  helpers ViewHelper
end

