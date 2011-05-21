begin
  require 'rocco/tasks'
  Rocco::make 'docs/', ["*.rb", "models/*.rb", "controllers/*.rb", "Rakefile"]

  desc 'Build rocco docs'
  task :docs => :rocco
  directory 'docs/'

  desc 'Build docs and open in browser for the reading'
  task :read => :docs do
    sh 'open docs/index.html'
  end

  %w[screen-datauri.css screen.css].each do |css|
    file "docs/#{css}" => "public/assets/#{css}" do |f|
      cp "public/assets/#{css}", "docs/#{css}", :preserve => true
    end
    task :docs => "docs/#{css}"
    CLEAN.include "docs/#{css}"
  end

  file 'docs/index.html' => 'views/static/doc_index.haml' do |f|
    system("haml -rrdiscount views/static/doc_index.haml docs/index.html")
  end

  task :docs => 'docs/index.html'
  CLEAN.include 'docs/index.html'

  # Alias for docs task
  task :doc => :docs

rescue LoadError
  warn "#$! -- rocco tasks not loaded."
end
