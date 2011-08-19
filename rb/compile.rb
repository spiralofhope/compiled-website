#!/usr/bin/ruby

=begin

CSS for <code>, <pre> and for tables..


bug: Making a new directory with a file in it isn't detected.

- remove the index.html from the listing of files, and put it up in the top nav.

If a new file is created, then re-create all files in that same directory - so as to update the navigation.
- CSS - including multiple stylesheets which the browser can switch between.  Maybe hardcode this so that there are multiple destination files.  They could also be leveraged for translated/alternate pages (styles, languages, draft version, old versions, notes, etc)
- Templating {{replacement file}}  {{subst:replacement file}}
 - generate a list of links in the footer to view/edit the templates being used?
- automatic linking [[link]]
- Syntax highlighting
- Make the header hidable if javascript is enabled.
- Footer - hosting logo and link
- Implement "view source" ?

Later:
- markup language changes

Far future:
- revision tracking

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

working_directory=File.expand_path(File.join('', 'home', 'user', 'live', 'Projects', 'compiled-website', '0.4.1'))
source_directory='source'
target_directory='httpdocs'
source_directory_path=File.expand_path(File.join(working_directory, source_directory))
target_directory_path=File.expand_path(File.join(working_directory, target_directory))

# Local website, like file:///tmp/mydir/website .. with no trailing slash
# $WEBSITE='file://' + File.join(target_directory_path)
# Full URL, like http://example.com .. with no trailing slash
# $WEBSITE="http://spiralofhope.com"
# TESTING: Removed the trailing slash
$WEBSITE="http://spiral.l4rge.com"

# TODO: Make the format something boring, and then make my own headers?  But bluefeather has some smart markup for generating the title and stuff.  Check into that stuff.
def markup(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file)
  if ! File.exists?(source_file) then
    puts "source_file does not exist, aborting: " + source_file.inspect
    abort
  end
  if ! File.exists?(target_directory_path) then
    md_directory(target_directory_path)
  elsif ! File.directory?(target_directory_path) then
    puts "target_directory_path exists, but it is not a directory, aborting: " + target_directory_path.inspect
    abort
  end
  # TODO: Make this a variable like I did before.. that'll help tidy this nonsense up..
  system('bluefeather --force --format d --output ' + target_directory_path + ' ' + source_file)
end

def viewer(file)
  # TODO: Make this a variable like I did before.. that'll help tidy this nonsense up..
  # TODO: Make this a proper method which checks for the existence of the file..
  file=File.expand_path(file)
#   system('links -g ' + file)
  # Firefox is busted and doesn't print directories properly.  Links works.  =/
  system('firefox --new-tab ' + file)
end

def header_search(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
  return '</head>\n<body>\n\n'
end
def header_replace(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file, target_file)
  source_file=File.expand_path(source_file)
  target_file=File.expand_path(target_file)
  # What to replace with
  return<<-HEREDOC
<link rel="icon" href="#{$WEBSITE}/images/favicon.ico" type="image/x-icon">
<link rel="shortcut icon" href="#{$WEBSITE}/images/favicon.ico" type="image/x-icon">
<link rel="stylesheet" type="text/css" href="#{$WEBSITE}/css/main.css" />
</head>
<body>
<a name id="top">
<div class="nav">
<div class="float-left">
<img align="left" src="#{$WEBSITE}/images/spiralofhope-96.png">
<br>
<font style="font-size:1.5em;"><font color="steelblue">S</font>piral of Hope</font>
<br>
<font style="font-size: 0.5em;">Better software is possible.</font>
</div>
<div class="float-right">
#{header_replace_navigation(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file, target_file)}
</div>
</div>
<a name="body">
<div class="main">

  HEREDOC
end
# Note that you better   cd_directory(source_directory_path) somewhere else before summoning this.  I don't want this routine constantly cd'ing.
def header_replace_navigation(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file, target_file)
  # TODO: Move this stuff up into something else, and then pass these variables along so they can be used elsewhere..
  elements=File.join(working_directory, target_directory).split(File::Separator).length
  # /home/user/live/Projects/compiled-website/0.3.5/httpdocs => 7
  # Carve up my target directory
  current_path=target_directory_path.split(File::Separator)
  # "/home/user/live/Projects/compiled-website/0.3.5/httpdocs/subdir" => ["", "home", "user", "live", "Projects", "compiled-website", "0.3.5", "httpdocs", "subdir"]
  # For every element in the original path
  elements.times do
    # Remove the start element
    current_path.shift
  end
  # This leaves only the trailing stuff, if anything.
  # Patch it back together.  This is the subdirectory that I'm currently working in.
  current_path=current_path.join(File::Separator)
  # "subdir"

  current_path_up=current_path.split(File::Separator)[0..-2].join(File::Separator)
  if current_path_up == "" then current_path_up='/' end
  # "subdir" => ""

  target_directory_path_up=target_directory_path.split(File::Separator)[0..-2].join(File::Separator)
  # "subdir" => ""

  navigation=Array.new
  # Home
  navigation << '<a href="' + $WEBSITE + '/index.html" accesskey="z">[&lt;&lt;]</a>' + "\n"
  # Up
  index=""
  if File.exists?(File.join(target_directory_path_up, 'index.html')) then index='/index.html' end
  if File.expand_path(target_directory_path_up) == File.expand_path(target_directory_path) ||
      target_directory_path_up == File.join(working_directory, target_directory)
    then current_path_up=''
  end
  navigation << '<a href="' + $WEBSITE + current_path_up + index + '" accesskey="x">[^]</a> ' + "\n"
  navigation << '<a href="file://' + source_file + '" accesskey="e">[edit]</a> ' + "\n"
 # Separate the nav from the dirs/files
  navigation << "<br>\n"

  # dirs/files
  navigation_directories=Array.new
  navigation_files=Array.new
  # Create a web-friendly path
  current_path_web='/' + current_path.split(File::Separator).join('/') + '/'
  if current_path_web == "/./" then current_path_web="/" end
  Dir[File.join(target_directory_path, '**')].each do |i|
    if File.directory?(i) then
      if File.exists?(File.join(i, 'index.html')) then append='/index.html#body' else append="/" end
      navigation_directories << '<a href="' + $WEBSITE + current_path_web + File.basename(i) + append + '">' + File.basename(i) + "</a><br>\n"
    else
      if File.extname(i) == ".html" then append='#body' else append="" end
      navigation_files << '<a href="' + $WEBSITE + current_path_web + File.basename(i) + append + '">' + File.basename(i) + "</a><br>\n"
    end
  end
  navigation_directories=navigation_directories.sort!
  navigation_files=navigation_files.sort!
  # TODO: I don't seem to be able to use <hr> with this design.. This should have better styling anyways.
  return navigation << navigation_directories << "<br>\n" << navigation_files
end

def footer_search(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
  return '</body>\n</html>\n\z'
end
def footer_replace(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
  return<<-HEREDOC
</body>
</html>
</div>
<div class="footer">
<img src="#{$WEBSITE}/images/spiralofhope-16.png"> Spiral of Hope / spiralofhope - <a href="mailto:@gmail.com">@gmail.com</a>
<br>
<img src="#{$WEBSITE}/images/l4rge_logo-16.png">Hosting provided by <a href="http://l4rge.com">l4rge.com</a>, <a href="#{$WEBSITE}/thanks.html#l4rge">thanks!</a>
</div>
<!-- Disable the extra JavaScript, until I'm told which tag I should use.   Maybe it's <REMOVEADS>-->
<REMOVEADS>
<noscript>
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


def search_replace(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file, target_file)
  # I originally had the header and footer done separately, but to keep performance high, I only check and do the header/footer stuff when rebuilding the file.
  # Header
  search=Regexp.new(header_search(working_directory, source_directory, target_directory, source_directory_path, target_directory_path))
  replace=header_replace(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file, target_file)
  original_contents=file_read(target_file)
  replacement_contents=multiline_replace(search, original_contents, replace)
  if original_contents != replacement_contents then
    vputs 'Applying the header to ' + target_file
    f = File.open(target_file, 'w')
      f.write(replacement_contents)
    f.close
  end
  # Footer
  search=Regexp.new(footer_search(working_directory, source_directory, target_directory, source_directory_path, target_directory_path))
  replace=footer_replace(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
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
def compile(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file)
  target_file=File.join(target_directory_path, File.basename(source_file, '.asc') + '.html')
  # Build missing files.
  if ! File.exists?(target_file) then
    vputs 'File does not exist, building ' + target_file
    markup(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file)
    search_replace(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file, target_file)
    timestamp_sync(source_file, target_file)
  end
  # Rebuild files with a different timestamp.
  # I realise that this will rebuild and overwrite a changed .html file, but the user should never change a target .html file directly but should instead be changing the .asc source file.
  # For some odd reason I can't wrap this into its own little helper method.
  stime=File.stat(source_file).mtime
  ttime=File.stat(target_file).mtime
  if stime != ttime then
    vputs "File times don't match, rebuilding " + target_file
    markup(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file)
    search_replace(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file, target_file)
    timestamp_sync(source_file, target_file)
    # TODO: Do this in a more friendly and configurable way.
    # FIXME: I can't append #body !!!
    system("firefox #{target_file}")
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
  target_directory_path=working_directory
  $HOME=target_directory_path

  md_directory(working_directory)
  md_directory(target_directory_path)
  create_file(File.join(working_directory, 'source.asc'), '**missing file**')
  # Test
  vputs "\n # source.html is missing, so it should be created."
  compile(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file)
  # Sleep to make sure the time is wrong for the second pass.
  vputs "\n------------------------------"
  sleep 1.1
  vputs "\n # Re-create the file with the new time."
  create_file(File.join(target_directory_path, 'source.asc'), '**wrong timestamp**')
#   system("\ls", "-lG", "--time-style=full-iso", working_directory)
  vputs "\n # source.html is there, but I re-created the source file so the time should now be wrong."
  compile(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file)
  vputs "\n # The time should now be right."
#   system("\ls", "-lG", "--time-style=full-iso", working_directory)

  vputs "\n # Trying a couple more times, there should be no processing."
  compile(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file)
  compile(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file)
  vputs "\n # There should not have been any output."

  vputs "\n # Now trying with the source in a subdirectory."
  md_directory(File.join(working_directory, 'subdir'))
  create_file(File.join(working_directory, 'subdir', 'source-in-subdir.asc'), '**source in a subdirectory**')
  source_file=File.join(working_directory, 'subdir', 'source-in-subdir.asc')
  compile(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file)

  vputs "\n # Now trying with the target in a subdirectory."
  md_directory(File.join(working_directory, 'subdir'))
  target_directory_path=File.expand_path(File.join(working_directory, 'subdir'))
  create_file(File.join(working_directory, 'target-in-subdir.asc'), '**target in a subdirectory**')
  source_file=File.join(working_directory, 'target-in-subdir.asc')
  compile(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file)

  vputs "\n # Now trying with the source and target in different subdirectories."
  md_directory(File.join(working_directory, 'source'))
  md_directory(File.join(working_directory, 'target'))
  source_directory_path=File.expand_path(File.join(working_directory, 'source'))
  target_directory_path=File.expand_path(File.join(working_directory, 'target'))
  create_file(File.join(source_directory_path, 'both-in-subdirs.asc'), '**source and target in different subdirectories**')
  source_file=File.join(source_directory_path, 'both-in-subdirs.asc')
  compile(working_directory, source_directory, target_directory, source_directory_path, target_directory_path, source_file)

  # Check
  viewall(working_directory)
  # Teardown
  sleep 3
  rm_directory(working_directory)
end # test_compile
# $VERBOSE=nil
# test_compile


def global_compile(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
  Dir['**/*.asc'].each do |source_file|
    target_directory_path_global=File.join(target_directory_path, File.dirname(source_file))
    source_file=File.expand_path(source_file)
    compile(working_directory, source_directory, target_directory, source_directory_path, target_directory_path_global, source_file)
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
  source_directory_path=File.expand_path(File.join(working_directory, 'source'))
  target_directory_path=File.expand_path(File.join(working_directory, 'target'))

  md_directory(working_directory)
  md_directory(source_directory_path)
  cd_directory(source_directory_path)
  md_directory(File.join(source_directory_path, 'subdir'))
  md_directory(File.join(source_directory_path, 'subdir', 'sub-subdir'))
  md_directory(target_directory_path)

  create_file(File.join(source_directory_path, 'source.asc'), '**content**')
  create_file(File.join(source_directory_path, 'subdir', 'subdir.asc'), '**content**')
  create_file(File.join(source_directory_path, 'subdir', 'sub-subdir', 'sub-subdir.asc'), '**content**')

  # TODO: This is a kludgy fix for the navigation.. I'm not sure what else to do..
  $HOME=target_directory_path

  # Test
  puts "\n # Creating missing files."
  global_compile(source_directory_path, target_directory_path, working_directory, target_directory)

  puts "\n # Re-try to ensure that everything went well."
  global_compile(source_directory_path, target_directory_path, working_directory, target_directory)
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

def main(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
  pid_file=File.join('', 'tmp', 'compile_child_pid')
  fork_killer(pid_file)
  cd_directory(source_directory_path)
  # The main loop - once a second.
  fork_helper(pid_file) {
    global_compile(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
  }
end
# If you made changes to the templating and need to re-create everything, then blank out all the files.
# If I delete all .html, they get rebuilt.  However, the navigation won't be correct since not 100% of the files will exist until the very last item in each directory is built.  The solution:  Don't delete the .html, just blank them out and let the rebuild work.
#  find -type f -name '*.html' -exec \cp /dev/null {} \;
def blank_all(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
  global(target_directory_path, '.html') {
    create_file($global_file, "")
  }
end
blank_all(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
# $VERBOSE=nil
main(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
# sleep 1
# viewer(File.join(target_directory_path, 'index.html'))
# sleep 3
# fork_killer(File.join('', 'tmp', 'compile_child_pid'))


__END__
