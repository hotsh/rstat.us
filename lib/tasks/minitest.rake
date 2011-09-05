require 'rake/testtask'

desc "Run all tests"
task :test do
  test_task = Rake::TestTask.new("alltests") do |t|
    t.test_files = Dir.glob(File.join("test", "**", "*_test.rb"))
  end
  task("alltests").execute
end

namespace :test do
  desc "Run all tests"
  task :all do
    Rake::Task["test"].invoke
  end

  desc "Run model tests"
  task :models do
    test_task = Rake::TestTask.new("modeltests") do |t|
      t.test_files = Dir.glob(File.join("test", "models", "**", "*_test.rb"))
    end
    task("modeltests").execute
  end

  desc "Run acceptance tests"
  task :acceptance do
    test_task = Rake::TestTask.new("acceptance") do |t|
      t.test_files = Dir.glob(File.join("test", "acceptance", "**", "*_test.rb"))
    end
    task("acceptance").execute
  end

  desc "Run single file"
  task :file, :file do |task, args|
    puts args.file
    test_task = Rake::TestTask.new("unittests") do |t|
      if args.file
        t.pattern = args.file
      else
        t.pattern = "test/models/*_test.rb"
      end
    end
    task("unittests").execute
  end
end
