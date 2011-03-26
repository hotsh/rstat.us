# Bring in Rocco tasks
require 'rocco/tasks'
Rocco::make 'docs/', ["*.rb", "models/*.rb", "Rakefile"]

desc 'Build rocco docs'
task :docs => :rocco
directory 'docs/'

desc 'Build docs and open in browser for the reading'
task :read => :docs do
  sh 'open docs/rstatus.html'
end

# Make index.html a copy of rstatus.html
file 'docs/index.html' => 'docs/rstatus.html' do |f|
  cp 'docs/rstatus.html', 'docs/index.html', :preserve => true
end
task :docs => 'docs/index.html'
CLEAN.include 'docs/index.html'

# Alias for docs task
task :doc => :docs
