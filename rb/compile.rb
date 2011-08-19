source_directory='source'
www_directory='www'

working_directory=File.expand_path(File.dirname(__FILE__))
source_directory_path=File.expand_path(File.join(working_directory, source_directory))
www_directory_path=File.expand_path(File.join(working_directory, www_directory))

# TODO: None of this seems right.  =/
$LOAD_PATH.unshift(File.join(working_directory, 'lib'))
require 'lib_misc.rb'
require 'lib_directories.rb'
require 'lib_files.rb'
require 'lib_strings.rb'

# Local website, like file:///tmp/mydir/website .. with no trailing slash
$WEBSITE='file://' + File.join(www_directory)
# Full URL, like http://example.com .. with no trailing slash
# $WEBSITE="http://spiralofhope.com"

def view_html(source_file_full_path)
  # TODO: Make this a proper method which checks for the existence of the file..
  # system('links -g ' + file)
  system('firefox --new-tab ' + source_file_full_path)
end



=begin
TODO list:
- Implement a hyphon - for unordered lists, and # for ordered lists
- Consider manual lists.. I count the lines and paint the numbers myself.  This will let me have broken lists like this:

# one
# two
<pre>
something
</pre>
# three
# four

- Have [http://example.com] type links, which become [1] etc, auto-numbered.
- A better 'listings' feature.  Just have it output the right CSS and let the user figure out how it ought to be displayed.  I'm tired of ;list: item
- colon (:) for indentation
- Manually-indent blocks between headers, like the original coWiki did.  I wonder what the HTML for that was.  Consider looking into my old archives, like my old RPG archives I sent to Angus.
- implement "new page" creation concepts.  I would make a link like [[link]] and then the system would point me to the appropriate source .asc file.  This would summon my editor as usual, and I can make the page very easily.
- tables, somehow..
- Create a for-print version that changes inline links into anchor links to a nice list of endnotes.  I could even tinyurl all those links automatically..
- Templating {{replacement file}}  {{subst:replacement file}}
=end


=begin
Requirements:
HTML Tidy
  http://tidy.sourceforge.net/

  cvs -d:pserver:anonymous@tidy.cvs.sourceforge.net:/cvsroot/tidy login
  cvs -z3 -d:pserver:anonymous@tidy.cvs.sourceforge.net:/cvsroot/tidy co -P tidy
  cd tidy/build/gmake
  make
  su
  make install


Notes:
TODO: I'd love to use Ruby/HTML Tidy, but I don't know how to make it go.
  http://tidy.rubyforge.org/
  http://rubyforge.org/projects/tidy
  http://tidy.rubyforge.org/classes/Tidy.html
  gem install tidy
=end

=begin
Usage:
- You can combine multiple markup by starting it all with spaces between them.
- wiki-style linking is done automatically, just type as usual and the engine will figure out the links.  Note that multiple words are given priority over single words.
=end

def markup(string, search_left, search_right, replace_left, replace_right, internal_markup_flag)
  def marked_yes(string, search_left, search_right, replace_left, replace_right)
    if string == nil then return '' end
    # TODO: If a link, check that the destination exists
    #  - local = create the file
    #  - remote = check if it exists, and cache the results?  Only check once a day?  Then I can redirect to a page if I know the link is bad, and create a notification to myself.. maybe updating a master status log file.
    if replace_left == nil && replace_right == nil then
      return string
    elsif replace_left == nil then
      return string.sub(search_right, replace_right)
    elsif replace_right == nil then
      return string.sub(search_left, replace_left)
    else
      return string.sub(search_left, replace_left).sub(search_right, replace_right)
    end
  end
  def marked_no(string, internal_markup_flag)
    if string == nil then return '' end
    if internal_markup_flag != true then
      # [:punct:] and [:blank:] don't work..
      start=/(^| )/
      punctuation=/(\.|,|!| |$)/

# TODO: If every regex has the same start and end block, I should somehow be able to remove that duplication.. but I'd have to research regexes more and maybe other stuff.  I'm not sure what to do.
# TODO: Something like this ought to work, but it just doesn't.  Boo.
# [
# [/\//, '<em>', '</em>'],
# [/\*\*/, '<big>', '</big>'],
# ].each do |i|
# puts i.inspect
# puts i[0].inspect
#   string=markup(string, %r{
#   (#{start})
#   #{i[0]}
#   },
#   %r{
#   #{i[0]}
#   (#{punctuation})
#   }, "\1#{i[1]}", "#{i[2]}\1", true)
# end

      string=markup(string, %r{(#{start})\/}, %r{\/(#{punctuation})}, '\1<em>', '</em>\1', true)
      string=markup(string, %r{(#{start})\*\*}, %r{\*\*(#{punctuation})}, '\1<big>', '</big>\1', true)
      string=markup(string, %r{(#{start})\*}, %r{\*(#{punctuation})}, '\1<b>', '</b>\1', true)
      string=markup(string, %r{(#{start})_}, %r{_(#{punctuation})}, '\1<u>', '</u>\1', true)
      string=markup(string, %r{(#{start})-}, %r{-(#{punctuation})}, '\1<s>', '</s>\1', true)
      string=markup(string, %r{(#{start})`}, %r{`(#{punctuation})}, '\1<tt>', '</tt>\1', true)
      # This one only matches stuff ending in .com, .ca, etc.
#       string=markup(string, /(^| )((http\:\/\/|ftp:\/\/|irc:\/\/|gopher:\/\/)(.*)(\....?))( |$)/, /( |$)/, '\1<a href="\2">\2</a> ', '\1', true)
      string=markup(string, /(^| )((http\:\/\/|ftp:\/\/|irc:\/\/|gopher:\/\/)(.*))( |$)/, /( |$)/, '\1<a href="\2">\2</a> ', '\1', true)

      internal_markup_flag=false
    end
    return string
  end

  processed=""
  # To avoid a runaway process, only handle 99 markup items on one single line:
  count=0
  until string == nil or count > 100 do
    count+=1
    string.match(/(#{search_left}.*?#{search_right})/)
    if $' != nil then
      string=$'
      processed=
        processed +
        marked_no($`, internal_markup_flag) +
        marked_yes($1, search_left, search_right, replace_left, replace_right)
    else
      # Deal with the remainder after a link.
      processed=processed + marked_no(string, internal_markup_flag)
      break # Stop this loop.
    end
  end
  return processed
end

# TODO:  Only allow one link for each file?  I'd have to maintain a working array of all the already-created links, and know if I'm creating a duplicate.
# TODO:  Possibly only one link for every header-section.  Somewhat more complex than the above, but really really worth it.
def get_files(directory)
  array=[]
  Dir["#{directory}/*.asc"].each do |file|
    next if not File.file?(file)
    # "/path/foo/file name.asc" => "file name"
    array << File.basename(file.chomp(File.extname(file)))
  end
  return array.sort
end
def automatic_linking(array_files, string)
  file_working=[]
  string.each do |line|
    array_files.each do |file|
      # 'some-example.html' => 'some example'
      # dashes become spaces
      file_string=file.gsub(/-/, ' ')
      # remove the ending .html
      file_string=file_string.sub(/\.html$/, '')

      file='./' + file + '.html'
      # Note: case-insensitivity is defined by the /i .. I don't think I'd ever want case-sensitivity.
      line=markup(line, /(#{file_string})/i, //, '<a href="' + file + '">\1</a>', '', true)
    end
    file_working << line
  end
  return file_working.to_s
end

# TODO:
def tidy_html(source_file_full_path)
  system("tidy --drop-empty-paras true --indent true --keep-time true --wrap 0 -clean -quiet -omit -asxhtml -access -modify --force-output true --show-errors 0 --show-warnings false --break-before-br true --tidy-mark false #{source_file_full_path}")
end

def compile(source_file_full_path, target_path)
  if ! File.exists?(source_file_full_path) then
    puts "source_file does not exist, aborting: " + source_file_full_path.inspect
    abort
  end
  if not File.exists?(target_path) then
    md_directory(target_path)
  elsif not File.directory?(target_path) then
    puts "target_path exists, but it is not a directory, aborting: " + target_path.inspect
    abort
  end

  target_file_contents='<p>' + markup(file_read(source_file_full_path), /<.+>/, /<.+>/, nil, nil, false) + '</p>'
  target_file_contents=automatic_linking(get_files(File.dirname(source_file_full_path)), target_file_contents)

  target_file_full_path=File.join(target_path, File.basename(source_file_full_path.chomp(File.extname(source_file_full_path))) + '.html')

  target_file_contents_processing=[]
  target_file_contents.each do |line|
    if line == "" then
      flag=true
      next
    end
    if flag == true then
      flag=false
    end
    target_file_contents_processing << line
  end

# TODO: This was an attempt at allowing lists.
#   target_file_contents.gsub!(/\n\n-/, "<ul><li>\1</li>")
#   target_file_contents.gsub!(/\n-/, "<li>\1</li>")
#   target_file_contents.gsub!(/\n\n-{1}.*\n\n/, "<li>\1</li></ul>")

  target_file_contents.gsub!(/(\n\n)/, "<\/p>\1<p>")

  # TODO: header
  # TODO: footer

  create_file(target_file_full_path, target_file_contents)
  tidy_html(target_file_full_path)
  # TODO: sync the timestamp
end
def test_compile()
  source_file_contents=<<-HEREDOC
*bold*, **big**. _underline_ /italics/ -strikethrough- `truetype`
Yes, this is legal in my code.  I'll just clean it up with HTML Tidy.:
  *two _words* test_
* _bold underline_ * _ *underline bold* _ _ * / underlined bold emphasis / * _
** * - _ / big bold strikethrough underlined emphasis / _ - * **
left <a href="http://example.com">no *markup* here</a> right
<nowiki>*test*</nowiki>  <anything>_yep_</> <>don't</>
left http://example.com right
http://invalid http://invalid.c
http://valid.ca
http://valid.com
ftp://cool.ca
*bold*._invalid_

this is some example text in *an _ example _ paragraph*

this is some text
this is someexample text
this issome example text
  HEREDOC

  working_directory=File.join('', 'tmp', "test_markup.#{$$}")
  md_directory(working_directory)

  create_file(File.join(working_directory, "some.asc"), "")
  create_file(File.join(working_directory, "some example.asc"), "")
  create_file(File.join(working_directory, "example.asc"), "")

  source_file=File.join(working_directory, 'source.asc')
  create_file(source_file, source_file_contents)

  compile(source_file, working_directory)

  target_file_full_path=File.join(working_directory, File.basename(source_file.chomp(File.extname(source_file))) + '.html')
  puts file_read(target_file_full_path)
end
# $VERBOSE=nil
# test_compile()

def compile_missing_file(source_file_full_path, target_path)
    vputs 'Building missing file:  ' + source_file_full_path.inspect
    compile(source_file_full_path, target_path)

    target_file_full_path=File.join(target_path, File.basename(source_file_full_path.chomp('.asc') + '.html'))
    timestamp_sync(source_file_full_path, target_file_full_path)

  view_html(target_file_full_path)

    # TODO: Re-compile all files in that same source directory, to ensure that automatic linking is re-applied to include this new file
end
def compile_different_timestamp(source_file_full_path, target_path)
    vputs 'Building unsynced timestamps:  ' + source_file_full_path.inspect
    compile(source_file_full_path, target_path)

    target_file_full_path=File.join(target_path, File.basename(source_file_full_path.chomp('.asc') + '.html'))
    timestamp_sync(source_file_full_path, target_file_full_path)

  view_html(target_file_full_path)
end

def main(source_directory_path, www_directory_path)
  pid_file=File.join('', 'tmp', 'compile_child_pid')
  fork_killer(pid_file)
  cd_directory(source_directory_path)
  # The main loop - once a second.
  fork_helper(pid_file) {
    Dir['**/*.asc'].each do |asc_file|
      target_file_full_path=File.expand_path(File.join(www_directory_path, asc_file.chomp('.asc') + '.html'))
      if not File.exists?(target_file_full_path) then
        source_file_full_path=File.expand_path(asc_file)
        compile_missing_file(source_file_full_path, target_file_full_path)
        next
      end
      source_file_full_path=File.expand_path(asc_file)
      source_time=File.stat(source_file_full_path).mtime
      target_time=File.stat(target_file_full_path).mtime
      if not source_time == target_time then
        target_path=File.join(www_directory_path, File.dirname(asc_file))
        compile_different_timestamp(source_file_full_path, target_path)
        next
      end
    end # Dir['**/*.asc'].each
  } # fork_helper
end # main

$VERBOSE=nil
main(source_directory_path, www_directory_path)
# sleep 1
# viewer(File.join(target_directory_path, 'index.html'))
# sleep 3
# fork_killer(File.join('', 'tmp', 'compile_child_pid'))


=begin
comments in a regular expression...

# incomplete
contents.gsub! %r{
  (
  \[Bindable)(\]
  \s*
  public
  \s+
  function
  \s+
  get
  \s+)
  (\w+) # property name $3
  \s*
  \([^)]*\)
....
}x, '\\1(event="\\3Change")\\2\\3...'
=end
