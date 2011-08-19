# I shouldn't rely on this..
# Separator = File::Separator

def vputs(string)
  # I don't explicityl say == true so as to allow values other than true/false.
  if $VERBOSE == true || $VERBOSE == nil then puts string end
end


def pid_exists?(pid)
  begin
    Process.kill(0, pid)
    # exists
    return 0
  rescue Errno::EPERM
    # changed uid
    return 128
  rescue Errno::ESRCH
    # does not exist or zombied
    # TODO: zombied?  That could be really bad.  I would want to kill-9 those, but I can't tell the difference between nonexistant and zombied.. argh argh argh!
    return 1
  rescue
    # Could not check the status?  See  $!
    return 255
  end
end


# Fork helper
# TODO: Allow a method before the loop and after the loop (in seppuku).  This prevents unnecessarily repeating code.  However, it introduces the issue of how I ought to pass variables around.  It's not worth the work right now, but it's a big issue to solve later.
def fork_killer(pid_file)
  lib = File.join('', 'home', 'user', 'bin', 'rb', 'lib')
  require File.join(lib, 'mine', 'misc.rb')
  require File.join(lib, 'mine', 'directories.rb')
  require File.join(lib, 'mine', 'files.rb')
  require File.join(lib, 'mine', 'exec.rb')
  require File.join(lib, 'mine', 'strings.rb')

  Dir[pid_file + '**'].each do |file|
    pid=File.extname(file)[1..-1].to_i
    # If the process exists:
    if pid_exists?(pid) == 0 then
      # Ask it to terminate.
      begin
        Process.kill("HUP", pid)
      rescue Errno::ESRCH
        vputs "**explosion!**"
      end
      # The exiting process will kill its own pid file.
    else
      vputs file + " doesn't actually have a running process.  Deleting it."
      File.delete(file)
    end
  end
end
def fork_helper(*args, &block)
  pid_file=args[0]
  # NOTE: This code has been copied verbatim.  If you need to edit it, edit the source misc.rb from which it came.
  lib = File.join('', 'home', 'user', 'bin', 'rb', 'lib')
  require File.join(lib, 'mine', 'misc.rb')
  require File.join(lib, 'mine', 'directories.rb')
  require File.join(lib, 'mine', 'files.rb')
  require File.join(lib, 'mine', 'exec.rb')
  require File.join(lib, 'mine', 'strings.rb')
  pid = fork do
    pidfile=pid_file + "." + $$.to_s
    create_file(pidfile, $$)
    def fork_helper_seppuku(pid_file)
        vputs "pid #{$$} was killed."
        # TODO: Appropriately-kill any other forked processes, and delete their pid files.
        File.delete(pid_file + "." + $$.to_s)
        exit
    end
    Signal.trap("HUP") { fork_helper_seppuku(pid_file) }
    Signal.trap("TERM") { fork_helper_seppuku(pid_file) }
    vputs "started #{$$}"
    until "sky" == "falling" do
#       vputs "pid #{$$} sleeping"
      yield
#       vputs "\n\n\n\n\n\n\n"
      sleep 1
    end
  end
end
def test_fork
  pid_file=File.join('', 'tmp' 'compile_child_pid')

  fork_killer(pid_file)
  a=1
  fork_helper(pid_file) {
    puts "process #{$$} is working.. #{a=a+1} seconds and counting."
  }
end
# test_fork
# Once your done testing, comment out test_fork and uncomment this.  It'll kill the one remaining fork.
fork_killer(File.join('', 'tmp', 'compile_child_pid'))


def echo(string)
  puts 'hey, stop using "echo"!'
  puts(string)
end


# read a single character from the console.
# This is referenced in some obscure error messages, so I'm commenting it out.  I suspect this is simply not portable code.
# begin
#   require "Win32API"
#   def read_char
#     Win32API.new("crtdll", "_getch", [], "L").Call
#   end
# rescue LoadError
#   def read_char
#     system "stty raw -echo"
#     STDIN.getc
#   ensure
#     system "stty -raw echo"
#   end
# end
