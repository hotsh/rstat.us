# coffee-script tasks
begin
  require 'coffee-script'
  require 'jammit'

  namespace :assets do
    desc "compile and compress application assets"
    task :compile do

      sh "compass compile views/screen.scss --output-style compressed --css-dir ../public/assets/src"
      source = "#{File.dirname(__FILE__)}/../public/js/"
      javascripts = "#{File.dirname(__FILE__)}/../public/assets/src/"

      Dir.foreach(source) do |cf|
        unless cf == '.' || cf == '..' || cf.end_with?('.coffee') == false
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
