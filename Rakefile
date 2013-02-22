#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

if ARGV[0] && ARGV[0].start_with?('test')
  load 'lib/tasks/minitest.rake'
else
  require File.expand_path('../config/application', __FILE__)
  RstatUs::Application.load_tasks
end
