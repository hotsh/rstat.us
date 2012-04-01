# Remove the rails-provided rake task for docs that we're not using
Rake.application.instance_variable_get('@tasks').delete('doc:app')

begin
  require 'rocco/tasks'

  desc 'Build rocco docs'
  task :rocco
  Rocco::make 'docs/', ["app/models/*.rb",
                        "app/controllers/*.rb",
                        "app/decorators/*.rb"]

  desc 'Build docs and open in browser for the reading'
  task :read => :rocco do
    sh 'open docs/index.html'
  end

  # Convenient aliases
  desc 'Build rocco docs'
  task :doc => :rocco
  desc 'Build rocco docs'
  task :docs => :rocco

rescue LoadError
  warn "#$! -- rocco tasks not loaded."
  task :rocco
end
