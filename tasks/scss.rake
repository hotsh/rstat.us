task :scss => 'public/s/screen.css'

file 'public/s/screen.css' => FileList['views/**/*.scss'] do
  sh "compass compile views/screen.scss --output-style compressed --css-dir public"
end