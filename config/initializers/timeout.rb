# Heroku will time out requests at 30 seconds and show an error to the user, but puma won't know
# that heroku has terminated the request early, so puma will keep working. This will tell puma to
# stop and will log a timeout exception.
Rack::Timeout.timeout = 25  # seconds