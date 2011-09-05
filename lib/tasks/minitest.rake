require 'rake/testtask'

desc "Run all tests"
task :test do
  test_task = Rake::TestTask.new("alltests") do |t|
    t.test_files = Dir.glob(File.join("test", "**", "*_test.rb"))
  end
  task("alltests").execute
end

namespace :test do
  desc "Run all tests (you can just do `rake test` now)"
  task :all do
    Rake::Task["test"].invoke
  end

  Dir.foreach("test") do |dirname|
    if dirname !~ /\.|coverage|data/ && File.directory?(File.join("test", dirname))
      desc "Run #{dirname} tests"
      task dirname do
        test_task = Rake::TestTask.new("#{dirname}tests") do |t|
          t.test_files = Dir.glob(File.join("test", dirname, "**", "*_test.rb"))
        end
        task("#{dirname}tests").execute
      end
    end
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
