require 'contest'

ENV['PATH'] = [File.expand_path('../../bin'), ENV['PATH']].join(':')

class ANSI2HTMLCommandTest < Test::Unit::TestCase
  test "piping stuff through a2h" do
    IO.popen("a2h", 'w+') do |io|
      io.sync = true
      io.puts "hello there"
      io.flush
      assert_equal "hello there\n", io.read("hello there\n".size)
      io.puts "and \x1b[1mhere's some bold"
      assert_equal "and <b>here's some bold\n", io.read(24)
      io.close_write
      assert_equal "</b>", io.read(4)
      io.close
    end
  end
end
