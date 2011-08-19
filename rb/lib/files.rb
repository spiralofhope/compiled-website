# TODO: This should refer to timestamp_different.. but since I have issues with that one, I'm not sure if I ought to..
def timestamp_sync(source_file, target_file, &block)
  if ! File.exists?(source_file) || ! File.exists?(target_file) then return 1 end
  stime=File.stat(source_file).mtime
  ttime=File.stat(target_file).mtime
  if stime != ttime then
#     puts "this should be displayed ONCE"
    vputs " # The source and target times are different.  Fixing the target time."
    vputs "   Source: #{source_file} to #{stime}"
    vputs "   Target: #{target_file} to #{ttime}"
    File.utime(stime, stime, target_file)
    if File.stat(target_file).mtime != stime then
      puts "Failed to set the time!"
      return 1
    end
    yield if block_given?
    return true
  else
#     vputs "The times are the same, doing nothing"
    return false
  end
end
def test_timestamp_sync
  # Setup
  lib = File.join('', 'home', 'user', 'bin', 'rb', 'lib')
  require File.join(lib, "mine", "misc.rb")
  require File.join(lib, "mine", "strings.rb")
  require File.join(lib, "mine", "directories.rb")
  require File.join(lib, "mine", "files.rb")
  # $$ is the pid of the current process.  That should make this safer.
  working_dir=File.join('', 'tmp', "test_timestamp_sync.#{$$}")
  source_file=File.join(working_dir, "source")
  target_file=File.join(working_dir, "target")
  # Preparing directories
  md_directory(working_dir)
  # Preparing files
  create_file(source_file, "content")
  # Sleep, to force the timestamp to be wrong
  sleep 1.5
  create_file(target_file, "content")
  # NOTE: The following code is not portable!
  system("\ls", "-lG", "--time-style=full-iso", working_dir)

  # Test
  puts " # First pass."
  timestamp_sync(source_file, target_file)
  puts " # Second pass."
  timestamp_sync(source_file, target_file)
  puts " # There should be no output."
  # Teardown
  # FIXME: Trap all errors and then perform my cleanup.  Fix all my test scripts to do this.
  # NOTE: The following code is not portable!
  system("\ls", "-lG", "--time-style=full-iso", working_dir)
  rm_directory(working_dir)
end
# test_timestamp_sync


def file_read(file)
  vputs "Reading file " + file
  # I suspect that there are issues reading files with a space in them.  I'm having a hard time tracking it down though.. TODO: I should adjust the test case.
  if ! File.exists?(file) then
    puts "That file doesn't exist"
    return ""
  end
  # TODO: Check permissions, etc.
# file=file.sub(' ', '_')
  f = File.open(file, 'r')
    string = f.read
  f.close
  return string
end
def test_file_read
  lib="~/bin/rb/lib/"
  require lib + "mine/misc.rb"
  require lib + "mine/files.rb"
  working_file="/tmp/test_file_read.#{$$}"
  create_file(working_file, "This is some content!")
  puts file_read(working_file)
  File.delete(working_file)
end



# http://www.ruby-doc.org/core/classes/File.html
# require 'ftools'


  # "here document", pickaxe2: 62, 361
  #Insert Desc_file_contents
  # file_contents = <<HEREDOC
  # this text appears in the file!
  # HEREDOC

# You can indent the final HEREDOC if you originally use <<-HEREDOC

# Example binary file:
# file_contents = <<HEREDOC
# \001
# \002
# \003
# \004
# \005
# HEREDOC

# TODO: This can't create a file if it's in a subdirectory that doesn't exist.  I get a TypeError.  Perhaps I could intelligently create the directory..
def create_file(file, file_contents)
  vputs "creating file: " + file
  # TODO: check that I have write access to my current directory.
  # TODO: check for overwriting an existing file
  begin
    File.open(file, 'w+') do |f| # open file for update
      f.print file_contents    # write out the example description
    end                                # file is automatically closed
  rescue Exception
    # TODO: Test this under Unix.  Developed under Windows, I can't remove write access to test this code.
    raise "Creating the text file #{file} has failed with: " + Exception
  end
end

def create_files(name, number)
  number.times{ |i|
    create_file(name + i.to_s)
  }
end

__END__

