# Created automatically by the [Draper gem](https://github.com/jcasimir/draper)
# Decorators common to multiple objects should go here.
class ApplicationDecorator < Draper::Base
  def format_timestamp(timestamp)
    timestamp.strftime("%a %b %d %H:%M:%S %z %Y")
  end
end
