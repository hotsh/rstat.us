namespace :css do
  desc "compile SASS to CSS"
  task :compile do
    system "compass compile views/screen.scss --output-style compressed --css-dir public"
  end
end
