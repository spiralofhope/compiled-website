# TODO: Ensure this in some nicer way.
require 'fileutils'

=begin
TODO:
I have not done proper testing on any of this.  I don't even know if "raise" works.  =p
=end
def cd_directory(directory)
  # This is the equivalent of:  directory=exec("readlink", "-f", Dir.getwd)
  directory=File.expand_path(directory)
  start_directory = Dir.getwd

  # TODO: Check permissions
  if directory == start_directory then
    vputs "cd_directory: I'm already in that directory"
    return 0
  end
  if ! File.directory?(directory) then
    raise RuntimeError, "cd_directory: That's not a directory:  " + directory
    return 1
  end
  if ! File.exists?(directory) then
    raise RuntimeError, "cd_directory: That directory doesn't exist:  " + directory
    return 1
  end

  vputs "cd_directory: entering directory: " + directory
  Dir.chdir(directory)
  # This is a good idea, but it fails if I'm in a symlinked directory..
  # TODO: Recursively check if I'm in a symlinked dir.  =)
#   if Dir.getwd != directory then
#     puts "cd failed.  I'm in\n" + Dir.getwd + "\n.. but you wanted \n" + directory
#     return 1
#   end
end

# Fix so that I can create a deep directory when parents don't yet exist.
def md_directory(directory)
  directory=File.expand_path(directory)
  if File.exists?(directory) then
    if File.directory?(directory) then
      # All is good!
      return 0
    else
      raise RuntimeError, "md_directory: It's a file, I can't make a directory of the same name! " + directory
      return 1
    end
  end
  # TODO: Suppress explosions using Signal.trap, and deal with things gracefully.  See misc.rb.  Apply this technique elsewhere/everywhere.
  vputs "md_directory: making directory: " + directory
  Dir.mkdir(directory)
  # Fails if I'm in a symlinked directory.  See notes with cd_directory.
#   if File.directory?(directory) == false then raise RuntimeError, "directory creation failed: " + directory end
  # TODO: ensure that I have complete access (read/write, make directories)
  # TODO: Attempt to correct the permissions.
end

# rm -rf
def rm_directory(directory)
  vputs "rm_directory: removing directory: " + directory
  directory=File.expand_path(directory)

  if ! File.exists?(directory) then
    # All is good!
    return 0
  end
  if ! File.directory?(directory) then
    raise RuntimeError, "rm_directory: That's a file, not a directory " + directory
    return 1
  end

  # Delete the directory and any files within it. _rf ignores standard error.
  # Another interesting method:  http://www.ruby-doc.org/core/classes/FileUtils.html#M004370
  #   FileUtils.remove_entry_secure(directory)
  FileUtils.rm_rf(directory)
  # Double-check that the remove worked.
  if File.exists?(directory) then
    raise RuntimeError, "rm_directory: The remove failed! " + directory
    return 1
  end
end

def mcd(directory)
  md_directory(directory)
  cd_directory(directory)
end

def rmd(directory)
  rm_directory(directory)
  md_directory(directory)
end

def rmcd(directory)
  rm_directory(directory)
  md_directory(directory)
  cd_directory(directory)
end

__END__

