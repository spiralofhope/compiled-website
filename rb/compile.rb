#!/usr/bin/ruby

=begin
TODO
- The issue I was having with firefox links is with some add-on or such!  -safe-mode works as-expected.

- CSS - including multiple stylesheets.

- Test with the remote website.  I'd have to add on another function to handle ftp:// and replace the /foo/bar/baz with the root of the website.. so generated links are correct.
- Templating {{replacement file}}  {{subst:replacement file}}
 - generate a list of links in the footer to view/edit the templates being used?
- automatic linking [[link]]
- Syntax highlighting
- Make the header hidable if javascript is enabled.
- Footer - spiral logo and copyright statement, contact link (picture of email addy)
- Footer - hosting logo and link


markup language changes..
=end

# ------------------
# Requirements:
# ------------------
=begin

TODO: Ensure requirements are met.
Ruby 1.8.6+

BlueFeather 0.22+
  http://ruby.morphball.net/bluefeather/index_en.html
  gem install bluefeather

=end


# -----------------
# Configuration
# -----------------
lib = File.join('', 'home', 'user', 'bin', 'rb', 'lib')
require File.join(lib, 'mine', 'misc.rb')
require File.join(lib, 'mine', 'directories.rb')
require File.join(lib, 'mine', 'files.rb')
require File.join(lib, 'mine', 'exec.rb')
require File.join(lib, 'mine', 'strings.rb')

working_directory=File.expand_path(File.join('', 'home', 'user', 'live', 'Projects', 'compiled-website', '0.2.1'))
source_directory=File.expand_path(File.join(working_directory, 'source'))
target_directory=File.expand_path(File.join(working_directory, 'httpdocs'))
$HOME=target_directory

# TODO: Make the format something boring, and then make my own headers?  But bluefeather has some smart markup for generating the title and stuff.  Check into that stuff.
def markup(source_file, target_directory)
  if ! File.exists?(source_file) then
    puts "source_file does not exist, aborting: " + source_file.inspect
    abort
  end
  if ! File.exists?(target_directory) then
    md_directory(target_directory)
  elsif ! File.directory?(target_directory) then
    puts "target_directory exists, but it is not a directory, aborting: " + target_directory.inspect
    abort
  end
  # TODO: Make this a variable like I did before.. that'll help tidy this nonsense up..
  system('bluefeather --force --format d --output ' + target_directory + ' ' + source_file)
end

def viewer(file)
  # TODO: Make this a variable like I did before.. that'll help tidy this nonsense up..
  # TODO: Make this a proper method which checks for the existence of the file..
  file=File.expand_path(file)
#   system('links -g ' + file)
  # Firefox is busted and doesn't print directories properly.  Links works.  =/
  system('firefox --new-tab ' + file)
end

def header_search(source_file, target_file, target_directory, working_directory)
  return '</head>\n<body>\n\n'
end
def header_replace(source_file, target_file, target_directory, working_directory)
  source_file=File.expand_path(source_file)
  target_file=File.expand_path(target_file)
  target_directory=File.expand_path(target_directory)
  # What to replace with
  return<<-HEREDOC
</head>
<body style="background-color: lightgrey;">
<a name id="top">

<p style="
  position: relative;
  min-width: 13em;
  max-width: 1000px;
  margin: 4em auto;
  border: 1px solid ThreeDShadow;
  -moz-border-radius: 10px;
  padding: 3em;
  -moz-padding-start: 30px;
  background-color: white;
">
<a href="file://#{$HOME}" accesskey="z">
#{
# TODO: I'm not sure how to avoid using $HOME.  =/
  if File.dirname(target_file) == $HOME then
    '<font color="green">[&lt;&lt;]</font>'
  else
    '[&lt;&lt;]'
  end
}
</a>
<a href="file://#{target_directory}" accesskey="x">[^]</a>
<a href="file://#{source_file}" accesskey="e">edit</a>
<br>
#{
  navigation_directories=Array.new
  navigation_files=Array.new
  Dir[File.join(target_directory, '**')].each do |i|
    if File.directory?(i) then
      if File.exists?(File.join(i, 'index.html')) then
        navigation_directories << '<a href="file://' + i + '/index.html"><font color="brown">' + File.basename(i) + '</font></a><br>'
      else
        navigation_directories << '<a href="file://' + i + '"><font color="brown">' + File.basename(i) + '</font></a><br>'
      end
    else
      if i == target_file then
        navigation_files << '<a href="file://' + i + '#body"><font color="green">' + File.basename(i) + '</font></a><br>'
      else
        navigation_files << '<a href="file://' + i + '#body">' + File.basename(i) + '</a><br>'
      end
    end
  end
  navigation_directories=navigation_directories.sort!
  navigation_files=navigation_files.sort!
  navigation_directories << navigation_files
  navigation_directories
}
</p>
<a name="body">
<div style="
  position: relative;
  min-width: 13em;
  max-width: 1000px;
  margin: 4em auto;
  border: 1px solid ThreeDShadow;
  -moz-border-radius: 10px;
  padding: 3em;
  -moz-padding-start: 30px;
  background-color: white;
">

  HEREDOC
end

def footer_search(source_file, target_file, target_directory, working_directory)
  return '</body>\n</html>\n\z'
end
def footer_replace(source_file, target_file, target_directory, working_directory)
  return<<-HEREDOC
</body>
</html>
</div>
<div style="
  position: relative;
  min-width: 13em;
  max-width: 1000px;
  margin: 4em auto;
">
A new footer too
</div>
  HEREDOC
end


# -------
# Setup
# -------

def viewall(directory)
  directory=File.expand_path(directory)
  # The **/ makes it do subdirectories too.
  Dir.glob(File.join(directory, '') + '**/*.html') { |file|
    file=File.expand_path(file)
    viewer(file)
  }
end


def search_replace(source_file, target_file, target_directory, working_directory)
  # I originally had the header and footer done separately, but to keep performance high, I only check and do the header/footer stuff when rebuilding the file.
  # Header
  search=Regexp.new(header_search(source_file, target_file, target_directory, working_directory))
  replace=header_replace(source_file, target_file, target_directory, working_directory)
  original_contents=file_read(target_file)
  replacement_contents=multiline_replace(search, original_contents, replace)
  if original_contents != replacement_contents then
    vputs 'Applying the header to ' + target_file
    f = File.open(target_file, 'w')
      f.write(replacement_contents)
    f.close
  end
  # Footer
  search=Regexp.new(footer_search(source_file, target_file, target_directory, working_directory))
  replace=footer_replace(source_file, target_file, target_directory, working_directory)
  original_contents=file_read(target_file)
  replacement_contents=multiline_replace(search, original_contents, replace)
  if original_contents != replacement_contents then
    vputs 'Applying the footer to ' + target_file
    f = File.open(target_file, 'w')
      f.write(replacement_contents)
    f.close
  end
end


# This expects proper full paths
def compile(source_file, target_directory, working_directory)
  target_file=File.join(target_directory, File.basename(source_file, '.asc') + '.html')

  # Build missing files.
  if ! File.exists?(target_file) then
    vputs 'File does not exist, building ' + target_file
    markup(source_file, target_directory)
    search_replace(source_file, target_file, target_directory, working_directory)
    timestamp_sync(source_file, target_file)
  end
  # Rebuild files with a different timestamp.
  # I realise that this will rebuild and overwrite a changed .html file, but the user should never change a target .html file directly but should instead be changing the .asc source file.
  # For some odd reason I can't wrap this into its own little helper method.
  stime=File.stat(source_file).mtime
  ttime=File.stat(target_file).mtime
  if stime != ttime then
    vputs "File times don't match, rebuilding " + target_file
    markup(source_file, target_directory)
    search_replace(source_file, target_file, target_directory, working_directory)
    timestamp_sync(source_file, target_file)
    # TODO: Do this in a more friendly and configurable way.
    system('firefox ' + target_file)
  end
end # compile
def test_compile
  lib = File.join('', 'home', 'user', 'bin', 'rb', 'lib')
  require File.join(lib, 'mine', 'misc.rb')
  require File.join(lib, 'mine', 'directories.rb')
  require File.join(lib, 'mine', 'files.rb')
  require File.join(lib, 'mine', 'exec.rb')
  require File.join(lib, 'mine', 'strings.rb')
  working_directory=File.join('', 'tmp', "test_global_compare.#{$$}")
  working_directory=File.expand_path(working_directory)
  source_file=File.join(working_directory, 'source.asc')
  target_directory=working_directory
  $HOME=target_directory

  md_directory(working_directory)
  md_directory(target_directory)
  create_file(File.join(working_directory, 'source.asc'), '**missing file**')
  # Test
  vputs "\n # source.html is missing, so it should be created."
  compile(source_file, target_directory, working_directory)
  # Sleep to make sure the time is wrong for the second pass.
  vputs "\n------------------------------"
  sleep 1.1
  vputs "\n # Re-create the file with the new time."
  create_file(File.join(target_directory, 'source.asc'), '**wrong timestamp**')
#   system("\ls", "-lG", "--time-style=full-iso", working_directory)
  vputs "\n # source.html is there, but I re-created the source file so the time should now be wrong."
  compile(source_file, target_directory, working_directory)
  vputs "\n # The time should now be right."
#   system("\ls", "-lG", "--time-style=full-iso", working_directory)

  vputs "\n # Trying a couple more times, there should be no processing."
  compile(source_file, target_directory, working_directory)
  compile(source_file, target_directory, working_directory)
  vputs "\n # There should not have been any output."

  vputs "\n # Now trying with the source in a subdirectory."
  md_directory(File.join(working_directory, 'subdir'))
  create_file(File.join(working_directory, 'subdir', 'source-in-subdir.asc'), '**source in a subdirectory**')
  source_file=File.join(working_directory, 'subdir', 'source-in-subdir.asc')
  compile(source_file, target_directory, working_directory)

  vputs "\n # Now trying with the target in a subdirectory."
  md_directory(File.join(working_directory, 'subdir'))
  target_directory=File.expand_path(File.join(working_directory, 'subdir'))
  create_file(File.join(working_directory, 'target-in-subdir.asc'), '**target in a subdirectory**')
  source_file=File.join(working_directory, 'target-in-subdir.asc')
  compile(source_file, target_directory, working_directory)

  vputs "\n # Now trying with the source and target in different subdirectories."
  md_directory(File.join(working_directory, 'source'))
  md_directory(File.join(working_directory, 'target'))
  source_directory=File.expand_path(File.join(working_directory, 'source'))
  target_directory=File.expand_path(File.join(working_directory, 'target'))
  create_file(File.join(source_directory, 'both-in-subdirs.asc'), '**source and target in different subdirectories**')
  source_file=File.join(source_directory, 'both-in-subdirs.asc')
  compile(source_file, target_directory, working_directory)

  # Check
  viewall(working_directory)
  # Teardown
  sleep 3
  rm_directory(working_directory)
end # test_compile
# $VERBOSE=nil
# test_compile


def global_compile(source_directory, target_directory, working_directory)
  Dir['**/*.asc'].each do |source_file_global|
    target_directory_global=File.join(target_directory, File.dirname(source_file_global))
    source_file_global=File.expand_path(source_file_global)
    compile(source_file_global, target_directory_global, working_directory)
  end
end # global_compile
def test_global_compile
  lib = File.join('', 'home', 'user', 'bin', 'rb', 'lib')
  require File.join(lib, 'mine', 'misc.rb')
  require File.join(lib, 'mine', 'directories.rb')
  require File.join(lib, 'mine', 'files.rb')
  require File.join(lib, 'mine', 'exec.rb')
  require File.join(lib, 'mine', 'strings.rb')
  working_directory=File.join('', 'tmp', "test_global_compare.#{$$}")
  working_directory=File.expand_path(working_directory)
  source_directory=File.expand_path(File.join(working_directory, 'source'))
  target_directory=File.expand_path(File.join(working_directory, 'target'))

  md_directory(working_directory)
  md_directory(source_directory)
  cd_directory(source_directory)
  md_directory(File.join(source_directory, 'subdir'))
  md_directory(File.join(source_directory, 'subdir', 'sub-subdir'))
  md_directory(target_directory)

  create_file(File.join(source_directory, 'source.asc'), '**content**')
  create_file(File.join(source_directory, 'subdir', 'subdir.asc'), '**content**')
  create_file(File.join(source_directory, 'subdir', 'sub-subdir', 'sub-subdir.asc'), '**content**')

  # TODO: This is a kludgy fix for the navigation.. I'm not sure what else to do..
  $HOME=target_directory

  # Test
  puts "\n # Creating missing files."
  global_compile(source_directory, target_directory, working_directory)

  puts "\n # Re-try to ensure that everything went well."
  global_compile(source_directory, target_directory, working_directory)
  puts " # You should not have seen any output."

  # Check
  viewall(working_directory)
  # Teardown
#   sleep 10
  rm_directory(working_directory)

end # test_global_compile
# $VERBOSE=nil
# test_global_compile

# ----------------
# The program
# ----------------

def main(source_directory, target_directory, working_directory)
  pid_file=File.join('', 'tmp', 'compile_child_pid')
  fork_killer(pid_file)
  cd_directory(source_directory)
  # The main loop - once a second.
  fork_helper(pid_file) {
    global_compile(source_directory, target_directory, working_directory)
  }
end
$VERBOSE=nil
# Delete all the .html files to force a complete rebuild.  This is good if you're screwing with templating and want to surf around.  FIXME Not working..  =/
# system('find', target_directory, '-type', 'f', '-name', '*.html', '-exec', 'rm', '{}', '\;')
main(source_directory, target_directory, working_directory)
sleep 1
viewer(File.join(target_directory, 'index.html'))
# sleep 3
# fork_killer(File.join('', 'tmp', 'compile_child_pid'))

__END__




