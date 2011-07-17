desc "Run unit tests"
task :test, :file do |task, args|
  puts args.file
  test_task = Rake::TestTask.new("unittests") do |t|
    if args.file
      t.pattern = args.file
    else
      t.pattern = "test/unit/*_test.rb"
    end
  end
  task("unittests").execute
end

namespace :test do

  desc "Run all tests"
  task :all do
    test_task = Rake::TestTask.new("all") do |t|
      t.pattern = "test/*/*_test.rb"
    end
    task("all").execute
  end

  desc "Run acceptance tests"
  task :acceptance do
    test_task = Rake::TestTask.new("acceptance") do |t|
      t.pattern = "test/acceptance/*_test.rb"
    end
    task("acceptance").execute
  end
end
