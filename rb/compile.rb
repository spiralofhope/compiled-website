#!/usr/bin/ruby

# TODO: Work with subdirectories.
# TODO: Scan for changes in any source files.  I could use an external program, or I could fork a thread which does this.  Mohahahaha..


# LIB="~/bin/rb/lib/"
# require LIB + "mine/misc.rb"
# require LIB + "mine/directories.rb"
# require LIB + "mine/files.rb"
# require LIB + "mine/exec.rb"
# require LIB + "mine/strings.rb"
# # code here
#
#
# __END__
# =begin

=begin

The reason this is done in Ruby and not sh is because I don't want to be forced to use GNU shit like sed.

Requirements:
-----------------

TODO: Ensure requirements are met.
Ruby 1.8.6+

BlueFeather 0.22+
  http://ruby.morphball.net/bluefeather/index_en.html
  gem install bluefeather

=end

# -----------------
# Configuration
# -----------------

lib ="~/bin/rb/lib/"
require lib + "mine/misc.rb"
require lib + "mine/directories.rb"
require lib + "mine/files.rb"
require lib + "mine/exec.rb"
require lib + "mine/strings.rb"

$working_dir="~/live/Projects/compiled-website/0.0.3/"
$source_dir=$working_dir + "source"
$destination_dir=$working_dir + "httpdocs"
# Force the overwriting of existing .html output files.
# TODO: Is there a way for me to figure out if I actually need to regenerate the html document?
# TODO: AHA!  Check the timestamp.  If it's different, then regenerate it and then clone the timestamp.
$markup="bluefeather --force --format d --output "
# $markup="bluefeather --format d --output "
$viewer="firefox --new-tab "

# -------
# Setup
# -------


def viewall(directory)
  directory=File.expand_path(directory)
  Dir.glob(directory + "/" + "*.html") { |file|
    file=File.expand_path(file)
    system($viewer + file)
  }
end

# -------------------
# Pre-processing
# -------------------

# subtitutions / templating

# ---------------------------
# Markdown conversion
# ---------------------------

def markdown_conversion_file(file, destination_directory)
  file=File.expand_path(file)
  system($markup + destination_directory + " " + file)
end

# Note that bluefeather is smart enough to not re-convert a file if it doesn't need to.
def markdown_conversion_directory(source_directory, destination_directory)
  source_directory=File.expand_path(source_directory)
  destination_directory=File.expand_path(destination_directory)
  # Convert all files
  Dir.glob(source_directory + "/" + "*.asc") { |file|
    markdown_conversion_file(file, destination_directory)
  }
end

def convert_all(source_dir, destination_dir)
  cd_directory(source_dir)
  markdown_conversion_directory(source_dir, destination_dir)
end
convert_all($source_dir, $destination_dir)

# --------------------
# Post-processing
# --------------------
# ----
# edit header
# ----
# Idea: I could have different headers per-file or per-directory or whatever..
def header_all(directory)
  cd_directory(directory)
  # For each file
  Dir.glob('*.html') { |file|
    # Open the file and read it into a variable.
    # TODO: Check permissions, etc.  Wrap this into a universal helper.
    f = File.open(file, 'r')
      string = f.read
    f.close

    match = Regexp.new('<body>\n\n')
    file_url=File.expand_path($source_dir + "/" + string_basename(file) + ".asc")
    header = <<-HEREDOC
<body>
<!-- header -->
<a href="#{file_url}" accesskey="e">edit</a>
HEY HEY!
<textarea rows="1" cols="1">
#{
      f = File.open(file_url, 'r')
        file_url_string = f.read
      f.close
      file_url_string
}
</textarea>
<!-- /header -->

    HEREDOC
# size = width

# It's all text - firefox extension
# https://addons.mozilla.org/en-US/firefox/addon/4125

    # Perform a replacement.
    new_string = multiline_replace(match, string, header)

    # If there's a change, write the changes back out.
    # TODO: Check permissions, etc.  Wrap this into a universal helper.
#     if string != new_string then
      f = File.open(file, 'w')
        f.write(new_string)
      f.close
#     end
  }
end

header_all($destination_dir)

# viewall($destination_dir)















# ---------
# Testing
# ---------

# TODO: Define specific test directories and files, so i can do a proper setup/teardown.
# $VERBOSE=true
def test_setup
  $working_dir="~/live/Projects/compiled-website/0.0.3/"
  $source_dir=$working_dir + "test_source"
  $destination_dir=$working_dir + "test_httpdocs"
  # heredoc
  $file_contents = <<-HEREDOC
hello world!

*I am formatted text!*
  HEREDOC

  cd_directory($working_dir)
  rmd($source_dir)
  rmd($destination_dir)
  cd_directory($source_dir)
  create_file("test.asc", $file_contents)
  create_file("test-two.asc", $file_contents)
end

def test_run
  cd_directory($source_dir)
  markdown_conversion_directory($source_dir, $destination_dir)

  cd_directory($destination_dir)
  viewall($destination_dir)
end

def test_teardown
  cd_directory($working_dir)
  rm_directory($source_dir)
  rm_directory($destination_dir)
end
# test_setup()
# test_run()
# test_teardown()

__END__

# notes can go here
