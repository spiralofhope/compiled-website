# This file is for stuff that is specific to the compiled website engine.
# Most of this was copied from the first generation of this codebase.

# used for FileUtils.mkdir_p
require 'fileutils'

def create_file(
                  file,
                  file_contents=''
                )
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
      raise "md_directory: It's a file, I can't make a directory of the same name!:  #{ directory.inspect }"
      return 1
    end
  end
  # TODO:  Suppress explosions using Signal.trap, and deal with things gracefully.
  #        e.g.  Signal.trap( "HUP" ) { method() }
  #        Apply this technique elsewhere/everywhere.
  vputs "md_directory: making directory:  #{ directory.inspect }"

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

def fork_helper(
                  *args,
                  &block
                )
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
    vputs "started pid:  #{ $$ }"
#    until "sky" == "falling" do
    loop do
#       vputs "pid #{ $$} sleeping"
      yield
#       vputs "\n\n\n\n\n\n\n"
      sleep 1
    end
  end
end
def test_fork()
  pid_file = File.join( '', 'tmp' 'test_fork_pid' )

  fork_killer( pid_file )
  fork_helper( pid_file ) {
    puts "process #{ $$ } is working:  #{ Time.now }"
  }
end
#test_fork()
# Once your done testing, comment out test_fork and uncomment this.  It'll kill the one remaining fork.
# fork_killer( File.join( '', 'tmp', 'test_fork_pid' ) )

def file_read( file )
  vputs "Reading '#{ file }'"
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

# TODO/FIXME:  Why the heck do I have a yield in there?
def timestamp_sync(
                    source_file,
                    target_file,
                    &block
                  )
  # TODO:  Sanity-checking.
  if ! File.exists?( source_file ) || ! File.exists?( target_file ) then return 1 end
  stime = File.stat( source_file ).mtime
  ttime = File.stat( target_file ).mtime
  if stime != ttime then
#     puts "this should be displayed ONCE"
    vputs " # The source and target times are different.  Fixing the target time."
    vputs "   Source: #{ source_file} to #{ stime }"
    vputs "   Target: #{ target_file} to #{ ttime }"
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
  working_dir = File.join( '', 'tmp', "test_timestamp_sync.#{ $$ }" )
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

=begin
TODO:  yield thing
- to the inside block
- to the outside block
- to the begin match
- to the end match
---> just do one yield with four parameters.
- The yield will be acting per-line.  To do something per-element the user would just do a normal array.each{}
=end

def line_partition(
                    string='',
                    # 1:  [ 'begin', 'end' ]
                    # 2:  [ [ 'begin1', 'end1' ], [ 'begin2', 'end2' ] ]
                    # 3:  [ [ [ 'begin1a', 'begin1b' ], [ 'end1a', 'end1b' ] ], [ [ 'begin2a', 'begin2b' ], [ 'end2' ] ] ]
                    # Elements can be of class String or Regex.
                    match_array=[],
                    # 'in', 'out', 'omit'
                    # in = include within the block.  xx<yy>zz => [ xx, <yy>, zz ]
                    # out = outside the block.        xx<yy>zz => [ xx<, yy, >zz ]
                    # omit = omit entirely.           xx<yy>zz => [ xx, yy, zz ]
                    begin_in_or_out='in',
                    end_in_or_out='in'
                  )
  #
  return '' if string == ''
  return '' if match_array == []
  #
  # This was built because I found that string.match(x) was slower than string == (x)  (for just using strings)
  # TODO:  Benchmarking
  #
  if match_array[0].class != Array then
    # using the simple syntax:  match_array = [ 'begin', 'end' ]
    #                       =>
    #                                         [ [ [ 'begin' ], [ 'end' ] ] ]
    # Beef it up.
    match_array.each_index{ |i|
      match_array[i] = [ match_array[i] ]
    }
    match_array = [ match_array ]
  elsif match_array[0][0].class != Array then
    # using the syntax:  match_array = [
    #                                    [ 'begin1a', 'end1a' ],
    #                                    [ 'begin2a', 'end2a' ]
    #                                  ]
    #                => 
    #                                  [
    #                                    [ [ 'begin1a' ], [ 'end1b' ] ],
    #                                    [ [ 'begin2a' ], [ 'end2a' ] ]
    #                                  ]
    # Beef it up.
    match_array[0].each_index{ |i|
      match_array[i].each_index{ |j|
        match_array[i][j] = [ match_array[i][j] ]
      }
    }
  end
  #
  result = [ '' ]
  active_close_tags = []
  #
  string.each_line{ |line|
    #
    matched = false
    #
    if active_close_tags == [] then
      # We're looking for a begin match.
      match_array.each_index{ |i|
        match_array[i][0].each{ |e|
          if match_found( line, e ) == true then
            matched = true
            active_close_tags = match_array[i][1]
            result << ''
            if begin_in_or_out == 'in' then
              result[-1].concat( line )
            elsif begin_in_or_out == 'out' then
              result[-2].concat( line )
            else
              # omit
            end
            break
          end
        }
      }
      if matched == false then
        # No match.
        # Append it.
        result[-1].concat( line )
      end
    else
      # We're in the middle of a block.
      # Look for an end match.
      active_close_tags.each{ |e|
        if match_found( line, e ) == true then
          matched = true
          active_close_tags = []
          result << ''
          if end_in_or_out == 'in' then
            result[-2].concat( line )
          elsif end_in_or_out == 'out' then
            result[-1].concat( line )
          else
            # omit
          end
          break
        end
      }
      if matched == false then
        # No match.
        # Append it.
        result[-1].concat( line )
      end
    end
  }
  return result
end
def match_found( string, matcher )
  return true if matcher.class == Regexp and string.match( matcher ) != nil
  return true if matcher.class == String and string.chomp == matcher.chomp
  return false
end
