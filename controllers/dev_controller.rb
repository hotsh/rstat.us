# This controller provides a development route for our css. Because we compile
# our CSS as part of deployment, it's really annoying when you're doing actual
# dev work. This route only gets included in the dev environment, and
# compiles the scss every time.
class Rstatus
  get '/dev/screen.css' do
    content_type 'text/css', :charset => 'utf-8'
    scss :screen, Compass.sass_engine_options
  end
end
