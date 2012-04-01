require 'rake/clean'

desc 'Update gh-pages branch'
task :pages => ['docs/.git', :rocco] do
  rev = `git rev-parse --short HEAD`.strip
  Dir.chdir 'docs' do
    sh "git add *.html"
    sh "git add app/controllers/*.html"
    sh "git add app/decorators/*.html"
    sh "git add app/models/*.html"
    sh "git add *.css"
    sh "git commit -m 'rebuild pages from #{rev}'" do |ok,res|
      if ok
        verbose { puts "gh-pages updated" }
        sh "git push -q o HEAD:gh-pages"
      end
    end
  end
end

file 'docs/.git' => ['docs/', '.git/refs/heads/gh-pages'] do |f|
  sh "cd docs && git init -q && git remote add o ../.git" if !File.exist?(f.name)
  sh "cd docs && git fetch -q o && git reset -q --hard o/gh-pages && touch ."
end
CLOBBER.include 'docs/.git'
