#!/usr/bin/ruby

=begin
FIXME: Moving a source file around will get a same name-generated directory created in www... odd.

FIXME: Making a new source directory with a .asc file in it isn't detected, because the destination directory doesn't exist yet.

- If a new file is created, then re-create all files in that same directory - so as to update the navigation.
- CSS - including multiple stylesheets which the browser can switch between.  Maybe hardcode this so that there are multiple destination files.  They could also be leveraged for translated/alternate pages (styles, languages, draft version, old versions, notes, etc)
- remove the directory listing and replace it with a sitemap feature - linked at the bottom of every page.
- find a way to hide the edit link and keep it accessible with an accesskey
- I need to figure out section editing eventually.
 - generate a list of links in the footer to view/edit the templates being used?
- Syntax highlighting
-- hpricot and syntax?  http://www.hokstad.com/syntax-highlighting-in-ruby.html
- Footer - hosting logo and link

Questions:
- Can I have BlueFeather automatically apply a class= to all the tags it automatically-generates?  That would be handy.
-- Alternately, I could have a post-processor which adds the tags if they're not found.  Maybe I ought to have some kind of data scraper or HTML helper which can assist with that.  Otherwise, I'd have to make it.

Later:
- rounded corners, using http://www.html.it/articoli/niftycube/index.html
- A show/hide for navigation and the header
-- But figure out how to remember the user preference when surfing.  Same with the stylesheet choice.

Far future:
- revision tracking

=end

# ------------------
# Requirements:
# ------------------
=begin

TODO: Ensure requirements are met.
I built this on:
- Ruby 1.8.6+
- BlueFeather 0.22+
  http://ruby.morphball.net/bluefeather/index_en.html
  gem install bluefeather

I don't know what specific versions are required.  BlueFeather claims it's for Ruby 1.9.x .. so I have no clue what's what.

=end



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
    <a class="without_u" accesskey="z" href="#{$WEBSITE}/index.html">
      <img align="left" src="#{$WEBSITE}/images/spiralofhope-96.png">
    </a>
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
    # Remove the start/leftmost element
    current_path.shift
  end
  # This leaves only the trailing stuff, if anything.
  # ["", "home", "user", "live", "Projects", "compiled-website", "0.3.5", "httpdocs", "subdir"] => ["subdir"]
  # Patch it back together.  This is the subdirectory that I'm currently working in.
  current_path=current_path.join(File::Separator)
  # ["subdir"] => "subdir"

  current_path_up=current_path.split(File::Separator)[0..-2].join(File::Separator)
  if current_path_up == "" then current_path_up='/' end
  # "subdir" => ""

  target_directory_path_up=target_directory_path.split(File::Separator)[0..-2].join(File::Separator)
  # "subdir" => ""

  navigation=Array.new
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
      if File.exists?(File.join(i, 'index.html')) then
        append='/index.html#body'
        prepend_name=''
        append_name=''
      else
        append='/'
        prepend_name='<font color="grey">'
        append_name='</font>'
      end
      navigation_directories << '<a href="' + $WEBSITE + current_path_web + File.basename(i) + append + '">' + prepend_name + File.basename(i) + '/' + append_name + "</a><br>\n"
    else
      if File.extname(i) == ".html" then append='#body' else append="" end
      if File.basename(i) == 'index.html' then next end
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
<div style="position:absolute; top:-1500px;"><noscript>
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






def test_compile
  working_directory=File.join('', 'tmp', "test_global_compare.#{$$}")
  source_file=File.join(working_directory, 'source.asc')
  target_directory_path=working_directory
  $HOME=target_directory_path

source_directory='source'
target_directory='httpdocs'

source_directory_path=File.expand_path(File.join(working_directory, source_directory))
target_directory_path=File.expand_path(File.join(working_directory, target_directory))

  $LOAD_PATH.unshift(File.join('', 'home', 'user', 'bin', 'rb', 'lib', 'mine'))
  require 'lib_misc.rb'
  require 'lib_directories.rb'
  require 'lib_files.rb'
  require 'lib_strings.rb'

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
test_compile





# If you made changes to the templating and need to re-create everything, then blank out all the files.
# If I delete all .html, they get rebuilt.  However, the navigation won't be correct since not 100% of the files will exist until the very last item in each directory is built.  The solution:  Don't delete the .html, just blank them out and let the rebuild work.
#  find -type f -name '*.html' -exec \cp /dev/null {} \;
def delete_all(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
  cd_directory(target_directory_path)
  Dir['**/*.html'].each do |file|
    File.delete(file)
  end
end
# delete_all(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
def blank_all(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)
  cd_directory(target_directory_path)
  Dir['**/*.html'].each do |file|
    create_file(file, "")
  end
end

# blank_all(working_directory, source_directory, target_directory, source_directory_path, target_directory_path)











def test_global_compile
  working_directory=File.join('', 'tmp', "test_global_compare.#{$$}")
  working_directory=File.expand_path(working_directory)
  source_directory_path=File.expand_path(File.join(working_directory, 'source'))
  target_directory_path=File.expand_path(File.join(working_directory, 'target'))

  $LOAD_PATH.unshift(File.join('', 'home', 'user', 'bin', 'rb', 'lib', 'mine'))
  require 'lib_misc.rb'
  require 'lib_directories.rb'
  require 'lib_files.rb'
  require 'lib_strings.rb'

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




__END__

#Before i realised that navigation was a stupid idea, I did this stuff:

    # TODO: Actually, maybe this should be tweaked to be very universal.  Just return an array of the files.
    # Let whatever other higher-up routine deal with the formatting of that array.
    def navigation(source_file_full_path, target_file_full_path)

      navigation=[]
      # Create a web-friendly path
      Dir[File.join(File.dirname(target_file_full_path), '**')].each do |i|
        # Future TODO: Subdirectories (see 0.5.4 and earlier)
        if File.extname(i) == ".html" then anchor='#body' else anchor="" end
        # This is /foo/file.ext compared with /bar/file.ext2 [if file == file]
        if File.basename(i, '.*') == File.basename(target_file_full_path, '.*') then
          prepend="<strong>"
          append="</strong>"
        else
          prepend=""
          append=""
        end
        navigation << prepend + '<a href="' + $WEBSITE + current_path_web + File.basename(i) + anchor + '">' + File.basename(i) + "</a>" + append + "<br>\n"
      end
      return navigation.sort!
    end