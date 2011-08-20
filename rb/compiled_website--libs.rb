# used for FileUtils.mkdir_p
require 'fileutils'

class String
  # http://stackoverflow.com/questions/3772864/how-do-i-remove-leading-whitespace-chars-from-ruby-heredoc/4465640#4465640
  # Bug-fixed:  If there is no indenting, this explodes.  I changed \s+ to \s*

  # Removes beginning-whitespace from each line of a string.
  # But only as many whitespace as the first line of text has.
  #
  # Meant to be used with heredoc strings like so:
  #
  # text = <<-EOS.unindent
  #   This line has no indentation
  #     This line has 2 spaces of indentation
  #   This line is also not indented
  # EOS
  #
  def unindent
    lines = Array.new
    self.each_line { |ln| lines << ln }

    first_line_ws = lines[0].match( /^\s*/ )[0]
    rx = Regexp.new( '^\s{0,' + first_line_ws.length.to_s + '}' )

    lines.collect { |line| line.sub( rx, "" ) }.join
  end

  # like Array.partition, but "global", in the same sense that `sub` has `gsub`
  def gpartition( rx )
    a = self.partition( rx )
    until a[-1].match( rx ) == nil do
      a[-1] = a[-1].partition( rx )
      a.flatten!
    end
    # Returns an array
    # Odd are the non-matches
    # Even are the matches
    # Always returns an odd number of elements
    #p 'uneven size!' if a.size.even?
    return a
  end

  # Like gpartition, except instead of a non-match returning [ (string), '', '' ] it returns [ (string) ]
  def gpartition2( rx )
    verboseold = $VERBOSE ; $VERBOSE=nil
    def gpartition2_remove_consecutive_empty_strings( array )
      if array[-1] == '' and array[-2] == '' then
        array.pop(2)
      else
        array.flatten!
      end
      return array
    end
    #
    a = gpartition2_remove_consecutive_empty_strings( self.partition( rx ) )
    until a[-1].match( rx ) == nil do
      a[-1] = gpartition2_remove_consecutive_empty_strings( a[-1].partition( rx ) )
    end
    #
    $VERBOSE=nil ; verboseold = $VERBOSE
    return a
    #return   a   if a.class == array
    #p '------------ what the hell?'
    #return [ a ] if a.class == string
    #p a, a.class
  end
end



# The below code was mostly copied from the first generation of this codebase.
# ---


def create_file( file, file_contents='' )
  # TODO: This can't create a file if it's in a subdirectory that doesn't exist.  I get a TypeError.  Perhaps I could intelligently create the directory..
  vputs "creating file:  '#{ file }'"
  # TODO: check that I have write access to my current directory.
  # TODO: check for overwriting an existing file.  Also implement an optional flag to overwrite it.
  begin
    File.open( file, 'w+' ) { |f| # open file for update
      f.print file_contents       # write out the example description
    }                             # file is automatically closed
  rescue Exception
    # TODO:  Causes issues, but I'm not sure why.
#    raise "\nCreating the text file #{ file.inspect } has failed with: "
  end
end

def vputs( string )
  if $VERBOSE == true || $VERBOSE == nil then
    puts string
  end
end

def cd_directory( directory )
  # TODO:  I have not done proper testing on any of this.  I don't even know if "raise" works.
  # This is the equivalent of:  directory = exec( "readlink", "-f", Dir.getwd )
  directory = File.expand_path( directory )
  start_directory = Dir.getwd

  # TODO: Check permissions
  if directory == start_directory then
    vputs "cd_directory: Already in that directory:  '#{ directory }'"
    return 0
  end
  if not File.directory?(directory) then
    raise "cd_directory: Not a directory:  '#{ directory }'"
    return 1
  end
  if not File.exists?(directory) then
    raise "cd_directory: Directory doesn't exist:  '#{ directory }'"
    return 1
  end

  vputs "cd_directory: Entering directory:  '#{ directory }'"
  Dir.chdir( directory )
  # This is a good idea, but it fails if I'm in a symlinked directory..
  # TODO: Recursively check if I'm in a symlinked dir.  =)
#   if Dir.getwd != directory then
#     puts "cd failed.  I'm in\n" + Dir.getwd + "\n.. but you wanted \n" + directory
#     return 1
#   end
end

# TODO:  Automatically make parent directories if they don't exist, like `md --parents`.
def md_directory( directory )
  directory = File.expand_path( directory )
  if File.exists?( directory ) then
    if File.directory?( directory ) then
      # All is good!
      return 0
    else
      raise "md_directory: It's a file, I can't make a directory of the same name!:  #{ directory.inspect}"
      return 1
    end
  end
  # TODO:  Suppress explosions using Signal.trap, and deal with things gracefully.
  #        e.g.  Signal.trap( "HUP" ) { method() }
  #        Apply this technique elsewhere/everywhere.
  vputs "md_directory: making directory:  #{ directory.inspect}"

  # This can make parent directories
  FileUtils.mkdir_p( directory )
  # This cannot make parent directories.  I could program a workaround so I don't need to require 'fileutils', but why?
  # Dir.mkdir( directory )

  # Fails if I'm in a symlinked directory.  See notes with cd_directory.
#   if File.directory?(directory) == false then raise "directory creation failed: " + directory end
  # TODO: ensure that I have complete access (read/write, make directories)
  # TODO: Attempt to correct the permissions.
end

def pid_exists?( pid )
  begin
    Process.kill( 0, pid )
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

def fork_killer( pid_file )
  # TODO: Allow a method before the loop and after the loop (in seppuku).  This prevents unnecessarily repeating code.  However, it introduces the issue of how I ought to pass variables around.  It's not worth the work right now, but it's a big issue to solve later.
  Dir[ pid_file + '**' ].each do |file|
    pid = File.extname( file )[1..-1].to_i
    # If the process exists:
    if pid_exists?( pid ) == 0 then
      # Ask it to terminate.
      begin
        Process.kill( "HUP", pid )
      rescue Errno::ESRCH
        vputs "**explosion!**"
      end
      # The exiting process will kill its own pid file.
    else
      vputs file + " doesn't actually have a running process.  Deleting it."
      File.delete( file )
    end
  end
end

def fork_helper( *args, &block )
  pid_file = args[0]
  pid = fork do
    pidfile = pid_file + "." + $$.to_s
    create_file( pidfile, $$ )
    def fork_helper_seppuku( pid_file )
        vputs "pid #{ $$} was killed."
        # TODO: Appropriately-kill any other forked processes, and delete their pid files.
        # 1.9.2 introduced an oddity where after a time this would get triggered twice.
        # Checking for existence is a cludgy workaround.
        if File.exists?( pid_file + "." + $$.to_s ) then
          File.delete(   pid_file + "." + $$.to_s )
        end
        exit
    end
    Signal.trap( "HUP"  ) { fork_helper_seppuku( pid_file ) }
    Signal.trap( "TERM" ) { fork_helper_seppuku( pid_file ) }
    vputs "started pid:  #{ $$}"
#    until "sky" == "falling" do
    loop do
#       vputs "pid #{ $$} sleeping"
      yield
#       vputs "\n\n\n\n\n\n\n"
      sleep 1
    end
  end
end
def test_fork
  pid_file = File.join( '', 'tmp' 'test_fork_pid' )

  fork_killer( pid_file )
  fork_helper( pid_file ) {
    puts "process #{ $$} is working:  #{ Time.now}"
  }
end
#test_fork()
# Once your done testing, comment out test_fork and uncomment this.  It'll kill the one remaining fork.
# fork_killer( File.join( '', 'tmp', 'test_fork_pid' ) )

def file_read( file )
  vputs "Reading file:  '#{ file }'"
  # I suspect that there are issues reading files with a space in them.  I'm having a hard time tracking it down though.. TODO: I should adjust the test case.
  if ! File.exists?( file ) then
    puts "That file doesn't exist:  '#{ file.inspect }'"
    return
  end
  # TODO: Check permissions, etc.
# file = file.sub( ' ', '_' )
  f = File.open( file, 'r' )
    string = f.read
  f.close
  return string
end
def test_file_read()
  lib = "~/bin/rb/lib/"
  # FIXME:  This shouldn't be requiring other stuff, that'd be bad testing!
  require lib + "mine/misc.rb"
  require lib + "mine/files.rb"
  working_file = "/tmp/test_file_read.#{ $$}"
  create_file( working_file, "This is some content!" )
  puts file_read( working_file )
  File.delete( working_file )
end


# ---

def timestamp_sync( source_file, target_file, &block )
  # TODO:  Sanity-checking.
  if ! File.exists?( source_file ) || ! File.exists?( target_file ) then return 1 end
  stime = File.stat( source_file ).mtime
  ttime = File.stat( target_file ).mtime
  if stime != ttime then
#     puts "this should be displayed ONCE"
    vputs " # The source and target times are different.  Fixing the target time."
    vputs "   Source: #{ source_file} to #{ stime}"
    vputs "   Target: #{ target_file} to #{ ttime}"
    File.utime( stime, stime, target_file )
    if File.stat( target_file ).mtime != stime then
      puts "Failed to set the time!"
      return 1
    end
    yield if block_given?
    return true
  else
    return false
  end
end
def test_timestamp_sync()
  # Setup
# FIXME:  Whoa, these dependencies need to be removed!
  lib = File.join( '', 'home', 'user', 'bin', 'rb', 'lib' )
  require File.join( lib, 'mine', 'misc.rb' )
  require File.join( lib, 'mine', 'strings.rb' )
  require File.join( lib, 'mine', 'directories.rb' )
  require File.join( lib, 'mine', 'files.rb' )
  # $$ is the pid of the current process.  That should make this safer.
  working_dir = File.join( '', 'tmp', "test_timestamp_sync.#{ $$}" )
  source_file = File.join( working_dir, 'source' )
  target_file = File.join( working_dir, 'target' )
  # Preparing directories
  md_directory( working_dir)
  # Preparing files
  create_file( source_file, 'content' )
  # Sleep, to force the timestamp to be wrong
  sleep 1.5
  create_file( target_file, 'content' )
  # NOTE: The following code is not portable!
  system( "\ls", "-lG", "--time-style=full-iso", working_dir )

  # Test
  puts " # First pass."
  timestamp_sync( source_file, target_file )
  puts " # Second pass."
  timestamp_sync( source_file, target_file )
  puts " # There should be no output."
  # Teardown
  # FIXME: Trap all errors and then perform my cleanup.  Fix all my test scripts to do this.
  # NOTE: The following code is not portable!
  system( '\ls', '-lG', '--time-style=full-iso', working_dir )
  rm_directory( working_dir )
end # test_timestamp_sync
