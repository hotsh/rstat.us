begin
  require 'rocco/tasks'
  Rocco::make 'docs/', ["app/models/*.rb", "app/controllers/*.rb"]

  desc 'Build rocco docs'
  task :docs => :rocco
  directory 'docs/'

  desc 'Build docs and open in browser for the reading'
  task :read => :docs do
    sh 'open docs/index.html'
  end

  # Alias for docs task
  task :doc => :docs

rescue LoadError
  warn "#$! -- rocco tasks not loaded."
end
