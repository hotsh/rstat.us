class TimeDecorator < ApplicationDecorator
  decorates :update

  def abbr
    h.content_tag "abbr",
                  {:class => "timeago",
                   :title => iso8601_time} do
      alps_time_span
    end
  end

  def permalink
    h.content_tag "time",
                  {:class    => "published",
                   :pubdate  => "pubdate",
                   :datetime => iso8601_time} do
      h.content_tag "a", {:class => "timeago",
                          :href  => update.url,
                          :rel   => "bookmark message",
                          :title => iso8601_time} do
        alps_time_span
      end
    end
  end

  private

  def alps_time_span
    h.content_tag "span", {:class => "date-time"} do
      alps_time
    end
  end

  def utc_time
    update.created_at.getutc
  end

  def iso8601_time
    utc_time.iso8601
  end

  def alps_time
    utc_time.strftime("%FT%T")
  end
end