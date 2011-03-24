require 'rake/testtask'
require 'rake/clean'

Rake::TestTask.new do |t|
  t.pattern = "test/*_test.rb" 
end 

# coffee-script tasks
require 'coffee-script'

namespace :js do
  desc "compile coffee-scripts from ./src to ./public/js"
  task :compile do
    source = "#{File.dirname(__FILE__)}/src/"
    javascripts = "#{File.dirname(__FILE__)}/public/js/"
    
    Dir.foreach(source) do |cf|
      unless cf == '.' || cf == '..' 
        js = CoffeeScript.compile File.read("#{source}#{cf}") 
        open "#{javascripts}#{cf.gsub('.coffee', '.js')}", 'w' do |f|
          f.puts js
        end 
      end 
    end
  end
end

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

# GITHUB PAGES ===============================================================

desc 'Update gh-pages branch'
task :pages => ['docs/.git', :docs] do
  rev = `git rev-parse --short HEAD`.strip
  Dir.chdir 'docs' do
    sh "git add *.html"
    sh "git commit -m 'rebuild pages from #{rev}'" do |ok,res|
      if ok
        verbose { puts "gh-pages updated" }
        sh "git push -q o HEAD:gh-pages"
      end
    end
  end
end

# Update the pages/ directory clone
file 'docs/.git' => ['docs/', '.git/refs/heads/gh-pages'] do |f|
  sh "cd docs && git init -q && git remote add o ../.git" if !File.exist?(f.name)
  sh "cd docs && git fetch -q o && git reset -q --hard o/gh-pages && touch ."
end
CLOBBER.include 'docs/.git'

