#!/usr/bin/ruby

# TODO: Begin the remote syncing stuff.  When I rebuild a file, also upload it.
# I should just mount an ftp folder locally.  That will make life very easy.. I could set $target there, and voila.

=begin

# ------------------
# Requirements:
# ------------------

TODO: Ensure requirements are met.
Ruby 1.8.6+

BlueFeather 0.22+
  http://ruby.morphball.net/bluefeather/index_en.html
  gem install bluefeather

=end


# -----------------
# Configuration
# -----------------

$working_dir=File.join('', 'home', 'user', 'live', 'Projects', 'compiled-website', '0.1.1')
$source=File.join($working_dir, 'source')
$target=File.join($working_dir, 'httpdocs')
# Force the overwriting of existing .html output files.
# TODO: Is there a way for me to figure out if I actually need to regenerate the html document?
# TODO: AHA!  Check the timestamp.  If it's different, then regenerate it and then clone the timestamp.
$markup="bluefeather --force --format d --output "
# $markup="bluefeather --format d --output "
$viewer="firefox --new-tab "
# $header must be defined directly within the code


# -------
# Setup
# -------

lib = File.join('', 'home', 'user', 'bin', 'rb', 'lib')
require File.join(lib, "mine", "misc.rb")
require File.join(lib, "mine", "directories.rb")
require File.join(lib, "mine", "files.rb")
require File.join(lib, "mine", "exec.rb")
require File.join(lib, "mine", "strings.rb")

def markdown_conversion_file(file, destination_directory)
  file=File.expand_path(file)
  destination_directory=File.expand_path(destination_directory)
  system($markup + destination_directory + " " + file)
end

# I should do all subdirectories too..
def viewall(directory)
  directory=File.expand_path(directory)
  Dir.glob(File.join(directory, '') + "*.html") { |file|
    file=File.expand_path(file)
    system($viewer + file)
  }
end


# Idea: I could have different headers per-file or per-directory or whatever..
# Perhaps I could summon global into subdirectories and treat those subdirectories with different headers..
def header_all(working_dir, source_dir)
$header_all_source_dir=source_dir
  def global_action(file)
    string=file_read(file)
    match=Regexp.new('</head>\n<body>\n\n')
    # FIXME: Being forced to do all this labour every loop is just plain stupid.  There must be a better way!  An overhaul is needed.
    source_file=File.join($header_all_source_dir, File.dirname(file), File.basename(file, ".html") + ".asc")
    target_file=File.join($target, File.dirname(file), File.basename(file))
    navigation=Array.new
    Dir[File.join(File.dirname(file), '**')].each do |file2|
      # TODO:  If the current file is being written, style the self-link.  In order to do this, I would have to overhaul this entire navigation concept.
      navigation << '<a href="file://' + File.join($target, file2) + '">' + File.basename(file2) + '</a><br>'
    end
    navigation=navigation.sort!
    # TODO: Go up to the previous directory.  I'm not sure how to do that in a portable way.
    # TODO: Implement a footer concept, so I can close off my body div.
    header=<<-HEREDOC
</head>
<body style="background-color: lightgrey;">
<!-- header -->
<p style="
  position: relative;
  min-width: 13em;
  max-width: 52em;
  margin: 4em auto;
  border: 1px solid ThreeDShadow;
  -moz-border-radius: 10px;
  padding: 3em;
  -moz-padding-start: 30px;
  background-color: white;
">
<a href="file://#{$target}" accesskey="z">[&lt;]</a>
<a href="file://#{File.dirname(target_file)}" accesskey="x">[^]</a>
<a href="file://#{source_file}" accesskey="e">edit</a>
<br>
#{ navigation }
</p>
<div style="
  position: relative;
  min-width: 13em;
  max-width: 52em;
  margin: 4em auto;
  border: 1px solid ThreeDShadow;
  -moz-border-radius: 10px;
  padding: 3em;
  -moz-padding-start: 30px;
  background-color: white;
">

<!-- /header -->

    HEREDOC

    # Perform a replacement.
    new_string = multiline_replace(match, string, header)

    # If there's a change, write the changes back out.
    # TODO: Check permissions, etc.  Wrap this into a universal helper.
    if string != new_string then
      f = File.open(file, 'w')
        f.write(new_string)
      f.close
      timestamp_sync(source_file, target_file)
    end
  end
  global(working_dir, '.html')
end
def test_header_all()
  lib = File.join('', 'home', 'user', 'bin', 'rb', 'lib')
  require File.join(lib, "mine", "misc.rb")
  require File.join(lib, "mine", "directories.rb")
  require File.join(lib, "mine", "files.rb")
  # Setup
  document=<<-HEREDOC
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>Incoming Calls - $25/year</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
<body>

<p>Some example text</p>

</body>
</html>
  HEREDOC
  working_dir=File.join('', 'tmp', "test_header_all.#{$$}")
  source_dir=working_dir
  md_directory(working_dir)
  create_file(File.join(working_dir, "1.html"), document)
  create_file(File.join(working_dir, "1.asc"), "content")
  create_file(File.join(working_dir, "2.html"), document)
  # Test
  header_all(working_dir, source_dir)
  $viewer="firefox --new-tab "
  system($viewer + File.join(working_dir, "1.html"))
  system($viewer + File.join(working_dir, "2.html"))
  # Teardown
  sleep 10
  rm_directory(working_dir)
end
# $VERBOSE=true
# $VERBOSE=nil
# test_header_all()

def global_compare()
  def global_action(file)
    source_file=File.expand_path(file)
    target_file=File.join($target, File.dirname(file), File.basename(file, '.asc') + '.html')
    # I could separate these, but for some reason I end up re-doing the time stuff.
    if File.exists?(target_file) == false then
      # Create the directory (if needed)
      # TODO - in directories.rb, I need to add a feature to build the tree of directories if a parent is missing.
      md_directory(File.dirname(target_file))
      vputs " # Missing file, rebuilding " + target_file
      markdown_conversion_file(source_file, File.dirname(target_file))
      timestamp_sync(source_file, target_file)
    end
    stime=File.stat(source_file).mtime
    ttime=File.stat(target_file).mtime
    if stime != ttime then
      vputs " # Different times, rebuilding " + target_file
      markdown_conversion_file(source_file, File.dirname(target_file))
      timestamp_sync(source_file, target_file)
    end
    # If you wanted to check the time at the commandline, do   \ls -al --time-style=full-iso .
  end # global_action
  global($source, '.asc')
end # global_compare
def test_global_compare()
  # Setup
  lib = File.join('', 'home', 'user', 'bin', 'rb', 'lib')
  require File.join(lib, "mine", "misc.rb")
  require File.join(lib, "mine", "strings.rb")
  require File.join(lib, "mine", "directories.rb")
  require File.join(lib, "mine", "files.rb")
  # $$ is the pid of the current process.  That should make this safer.
  $working_dir=File.join('', 'tmp', "test_global_compare.#{$$}")
  $source="#{$working_dir}/source"
  $target="#{$working_dir}/httpdocs"

  # Preparing directories
  md_directory($working_dir)
  md_directory($source)
  md_directory(File.join($source, "subdirectory"))
  md_directory($target)
  # Preparing files
  create_file(File.join($source, "1-timestamp.asc"), "content")
  create_file(File.join($source, "subdirectory", "2-notexisting.asc"), "content")
  # Force the timestamp to be wrong for example1.html
  sleep 1
  create_file(File.join($target, '1-timestamp.html'), "content")
  # example 2 is missing and should be created.

  # Test
  global_compare()
  puts " # Second pass.  It shouldn't find anything to do.."
  global_compare()
  # Teardown
#   rm_directory($working_dir)
end
# $VERBOSE=true
# $VERBOSE=nil
# test_global_compare()
# sleep 3
# viewall($target)

# The main loop - once a second.
def fork_helper_looped()
  global_compare()
  header_all($target, $source)
end


# ----------------
# The program
# ----------------

def main()
  pid_file=File.join('', 'tmp', 'compile_child_pid')
  fork_killer(pid_file)
  fork_helper(pid_file)
end
# $VERBOSE=true
# $VERBOSE=nil
main()
sleep 1
# system($viewer + File.join($target, 'test.html'))
# system($viewer + File.join($target, 'test', 'subdir.html'))
# Once your done testing, comment out test_fork and uncomment this.  It'll kill the one remaining fork.
# sleep 3
# fork_killer("/tmp/compile_child_pid")
# Delete all the .html files to force a complete rebuild.  This is good if you're screwing with templating and want to surf around.
system("find", $target, "-type", "f", "-name", "*.html", "-exec", "rm", "{}", "\;")

__END__
