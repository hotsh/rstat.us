# coffee-script tasks
begin
  require 'coffee-script'
  require 'jammit'

  namespace :assets do
    desc "compile coffee-scripts from ./src to ./public/js"
    task :compile do
      source = "#{File.dirname(__FILE__)}/../src/"
      javascripts = "#{File.dirname(__FILE__)}/../public/js/"

      sh "compass compile views/screen.scss --output-style compressed --css-dir public/assets"

      Dir.foreach(source) do |cf|
        unless cf == '.' || cf == '..' 
          js = CoffeeScript.compile File.read("#{source}#{cf}") 
          open "#{javascripts}#{cf.gsub('.coffee', '.js')}", 'w' do |f|
            f.puts js
          end 
        end 
      end      
      
      Jammit.package!    
    end
  end
rescue LoadError
  warn "#$! -- error compiling assets."
end
