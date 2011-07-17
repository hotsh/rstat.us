task :cron do
  Rake::Task["jobs:work"].invoke
end
