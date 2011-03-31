class Rstatus

  get '/dev/screen.css' do
    content_type 'text/css', :charset => 'utf-8'
    scss :screen, Compass.sass_engine_options
  end

end