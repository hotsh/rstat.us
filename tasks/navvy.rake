begin
  require 'navvy/tasks'
rescue LoadError
  task :navvy do
    abort "Couldn't find Navvy." << 
    "Please run `gem install navvy` to use Navvy's tasks."
  end
end
