#
# rb_main.rb
# DoItLive
#
# Created by Blake Mizerany on 6/27/10.
# Copyright __MyCompanyName__ 2010. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'

# Loading all the Ruby project files.
main = File.basename(__FILE__, File.extname(__FILE__))
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Dir.glob(File.join(dir_path, '*.{rb,rbo}')).map { |x| File.basename(x, File.extname(x)) }.uniq.each do |path|
  if path != main
    require(path)
  end
end

require 'optparse'

def usage
  abort("Usage: #$0 URL")
end

usage if ARGV.empty?

DoItLiveController::Options[:url] = ARGV[0]

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)
