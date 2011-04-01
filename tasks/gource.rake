# To use gource you will need to have gource installed on your system. If you use a mac you can use hombrew or ports to install it. If you are on linux check to see if your distro has a package or you can get it from here http://code.google.com/p/gource/

namespace :gource do
  desc "Build gource file"
  task :build do
    root_path = "#{File.dirname(__FILE__)}/../"
    #system("cd #{root_path}; perl gource/get_avatars.pl")
    system("cd #{root_path}; gource --seconds-per-day 2 -800x600 --disable-progress --stop-at-end --bloom-multiplier .4 --bloom-intensity 1.5 --hide-filenames --output-framerate 30 --user-image-dir .git/avatar --output-ppm-stream gource/rstatus.ppm .")
    system("cd #{root_path}; ffmpeg -y -b 3000k -r 30 -f image2pipe -vcodec ppm -i gource/rstatus.ppm -vcodec libx264 -vpre hq -vpre fastfirstpass gource/rstatus-video.mp4")
    system("cd #{root_path}; rm gource/rstatus.ppm")
  end
  
  task :avatars do
    root_path = "#{File.dirname(__FILE__)}/../"
    system("cd #{root_path}; perl gource/get_avatars.pl")
  end
end