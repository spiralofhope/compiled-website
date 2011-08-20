=begin
Usage:
- You can combine multiple markup by starting it all with spaces between them.
- wiki-style linking is done automatically, just type as usual and the engine will figure out the links.  Note that multiple words are given priority over single words.
=end
=begin
Requirements:
HTML Tidy
  http://tidy.sourceforge.net/

  cvs -d:pserver:anonymous@tidy.cvs.sourceforge.net:/cvsroot/tidy login
  # press enter
  cvs -z3 -d:pserver:anonymous@tidy.cvs.sourceforge.net:/cvsroot/tidy co -P tidy
  cd tidy/build/gmake
  make
  su
  smart install libxslt-proc
  make install
  # tested and works on Unity Linux 64bit as of 2010-04-12


Notes:
TODO: I'd love to use Ruby/HTML Tidy, but I don't know how to make it go.
  http://tidy.rubyforge.org/
  http://rubyforge.org/projects/tidy
  http://tidy.rubyforge.org/classes/Tidy.html
  gem install tidy
=end



=begin
TODO list:
- what does 'abort' do?  Is it some routine I have in a library somewhere?
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

# No trailing slashes
# The directory with the original .asc files
source_directory='local/source'
# The directory with the cached hybrid asc-html files:  asc-markup => html-markup
# The directory with the completed html files
compiled_directory='local/compiled'
# TODO: A variable for the web browser?  Seems non-obvious..

source_directory=File.expand_path(File.join(File.dirname(__FILE__), '..', source_directory))
compiled_directory=File.expand_path(File.join(File.dirname(__FILE__), '..', compiled_directory))

# Local website, like file:///tmp/mydir/website .. with no trailing slash
$WEBSITE='file://' + compiled_directory
# Full URL, like http://example.com .. with no trailing slash
# $WEBSITE="http://spiralofhope.com"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'lib_misc.rb'
require 'lib_directories.rb'
require 'lib_files.rb'
require 'lib_strings.rb'

def sanity_check(source_directory, compiled_directory)
  # Check for source_directory
  #The graceful way would be to leverage lib_directories//cd_directory and trap the RunTimeError that can be raised.
  if not File.directory?(source_directory) then
    # not a directory (doesn't exist, or it's a file)
    if not File.exists?(source_directory) then
      # nothing exists there
      md_directory(source_directory)
      # TODO: make an example file...
    else
      # a file!
      raise RuntimeError, "There's a file where I'm expecting your source_directory:  " + source_directory.inspect
      abort
    end
  end

  # Check for compiled_directory
  #The graceful way would be to leverage lib_directories//cd_directory and trap the RunTimeError that can be raised.
  if not File.directory?(compiled_directory) then
    # not a directory (doesn't exist, or it's a file)
    if not File.exists?(compiled_directory) then
      # nothing exists there
      md_directory(compiled_directory)
    else
      # a file!
      raise RuntimeError, "There's a file where I'm expecting your compiled_directory:  " + compiled_directory.inspect
      abort
    end
  end
end
sanity_check(source_directory, compiled_directory)

# TODO:  Implement a wmctrl thingy to raise the firefox window.  But apparently it's not possible!!
# http://localhost/wiki/Wmctrl_examples#Firefox_is_not_visible_in_the_list_of_managed_windows
def view_html(file_full_path)
  if File.exists?(file_full_path) then
    #system('links -g ' + file_full_path)
    #system('firefox', '-new-tab', file_full_path)
    system('firefox', file_full_path)
  else
    raise RuntimeErrror, "(view_html) file does not exist, aborting:  " + file_full_path.inspect
    abort
  end
end
def tidy_html(source_file_full_path)
  system('tidy', '--drop-empty-paras', 'true', '--indent', 'true', '--keep-time', 'true', '--wrap', '0', '-clean', '-quiet', '-omit', '-asxhtml', '-access', '-modify', '--force-output', 'true', '--show-errors', '0', '--show-warnings', 'false', '--break-before-br', 'true', '--tidy-mark', 'false', source_file_full_path)
end

def compile(source_file_full_path, target_file_full_path)
  # TODO:  Only allow one document-link within each file?  I'd have to maintain a working array of all the already-created links, and know if I'm creating a duplicate.  Not too tough to do
  # TODO:  Allow additional document-links, but only one document-link for each header-section.  Somewhat more complex than the above, but really really worth it.

  def sanity_check(source_file_full_path, target_file_full_path)
    if not File.exists?(source_file_full_path) then
      raise RuntimeError, "source_file_full_path does not exist, aborting:  " + source_file_full_path.inspect
      abort
    elsif File.directory?(source_file_full_path) then
      raise RuntimeError, "source_file_full_path is actually a directory:  " + source_file_full_path.inspect
      abort
    end
    # Future TODO:  If I ever do nested linking, I should make sure that the parent director(y|ies) exist.
  end
  sanity_check(source_file_full_path, target_file_full_path)
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
    # TODO: Or maybe have a simple timer?
    #       What can I do to report such an issue, so that it can be debugged?
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
  def automatic_linking(directory, string)
=begin
TODO: How to link long chains of multiple words before smaller chains or single-words:
- some_variable=""
- (done) iterate through each word individually (that's 'current')
- check for some_variable+current

... then something like:

if matched, look ahead one word
  if matched
    some_variable += current
  else
    deposit some_variable and current back in the completed string
else
  deposit some_variable and current back in the completed string
end

=end

    # Future TODO:  Allow linking into subdirectory-index.html and subdirectory/*.asc (etc)
    # Get the files in the present directory:
    array_files=[]
    Dir["#{directory}/*.asc"].each do |file|
      next if not File.file?(file)
      # "/path/foo/file name.asc" => "file name"
      array_files << File.basename(file.chomp(File.extname(file)))
    end
    array_files.sort!

    file_working=[]
    string.each do |line|
      array_files.each do |file|
        # remove the ending .html
        file_string=file.sub(/\.html$/, '')

        file='./' + file + '.html'
        # Note: case-insensitivity is defined by the /i .. I don't think I'd ever want case-sensitivity.
        # I'm being pretty cheap here.  Instead of being smart about auto-linking URLs, and intentionally avoiding odd broken-assed web+local links, I'm limiting what things can be auto-linked as local links.
        line=markup(line, /(^| )(#{file_string})($| )/i, //, '\1<a href="' + file + '">\2</a>\3', '', true)
      end
      file_working << line
    end
    return file_working.to_s
  end
  def header_and_footer(string, source_file_full_path)
    header_search = Regexp.new('')
    header_replace=<<-"HEREDOC"
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
<!-- navigation goes here -->
  </div>
</div>
<a name="body">
<div class="main">
    HEREDOC

    # '~~~~FOOTER~~~~' is a totally hackish thing for me to do, but oh well.
    # Could I search for the EOF or something cool?  Or just.. directly append this to do the bottom perhaps.
    footer_search=Regexp.new('~~~~FOOTER~~~~')
    puts footer_search
    footer_replace=<<-"HEREDOC"
          </div> <!-- main -->
          <div class="footer">
            <img border="0" src="#{$WEBSITE}/images/spiralofhope-16.png"> Spiral of Hope / <a href="mailto:@gmail.com">spiralofhope</a><a href="mailto:@gmail.com">@gmail.com</a>
            <br>
            <!-- TODO -->
            <img border="0" src="#{$WEBSITE}/images/FIXME.png">Hosting provided by (FIXME), <a href="#{$WEBSITE}/thanks.html#FIXME">thanks!</a>
            <br>
            <em><small>(<a href="#{$WEBSITE}/sitemap.html">sitemap</a>)</small></em>
            <br>
            <a class="without_u" accesskey="e" href="file://#{source_file_full_path}">&nbsp;</a>
          </div> <!-- footer -->
        </body>
      </html>
    HEREDOC

    string=multiline_replace(header_search, string, header_replace)
    string=multiline_replace(footer_search, string, footer_replace)
    return string
  end
  # TODO: This does not allow lists of mixed types (e.g. ordered within unordered)
  #       I don't know that I care to fix this..
  def lists(string, regex, opening, closing, line_start, line_end, line_continuation)
    # working with lists!
    result=[]
    previous_nesting=0
    # FIXME: This won't end correctly if the list ends with EOF.  Not a big deal since TidyHTML will probably fix it, but I should code this better.
    string.each do |line|
      # Search for the list..
      line =~ regex
      if $~ != nil then
        # I'm in a list.
        # Specify what nesting level I'm in.
        current_nesting = $~[1].length
        if previous_nesting == 0 then
          # This is the first item.
          # Add the HTML elements to the line.
          line = line_start + $~[2] + line_end
        else
          # We're continuing an existing list.
          # Add the HTML elements to the line.
          line = line_continuation + line_start + $~[2] + line_end
        end
        if current_nesting > previous_nesting then
          # I'm up a level.
          line = opening + line
        elsif current_nesting < previous_nesting then
          # I'm down one or more levels.
          line = ( closing * (previous_nesting - current_nesting)) + line
        else
          # I'm at the same level.
          # Nothing special needs to be done, I've already added the HTML elements to the line.
          line = line
        end
      else
        # not in a list.
        current_nesting=0
        if previous_nesting > 0 then
          # I'm down one or more levels (to the last level from a list).
          line=( closing * (previous_nesting - current_nesting)) + line
        else
          # I'm at the same level (I wasn't nested before).
          # Nothing special needs to be done.
          line = line
        end
      end
      previous_nesting=current_nesting
      result << line
    end
    return result.to_s
  end

  def compile(source_file_full_path, target_file_full_path)
    contents=file_read(source_file_full_path)
    contents=markup(contents, /<.+>/, /<.+>/, nil, nil, false)
    contents=automatic_linking(File.dirname(source_file_full_path), contents)
    # Unordered lists
    contents=lists(contents, /^(-+) (.*)$/, '<ul>', '</ul>', '<li>', '</li>', '')
    # Ordered lists
    contents=lists(contents, /^(#+) (.*)$/, '<ol>', '</ol>', '<li>', '</li>', '')
    # Code blocks
    contents=lists(contents, /^( )(.+)$/, '<pre>', '</pre>', '', '', '<br>')
    # '~~~~FOOTER~~~~' is a totally hackish thing for me to do, but oh well.
    # I should just redo this to make it a simple header + contents + footer.. eesh.
    contents=header_and_footer(contents + '~~~~FOOTER~~~~', source_file_full_path)

    # Headers
    contents.gsub!(/^= (.*) =$/, '<h1>\1</h1>')
    contents.gsub!(/^== (.*) ==$/, '<h2>\1</h2>')
    contents.gsub!(/^=== (.*) ===$/, '<h3>\1</h3>')
    contents.gsub!(/^==== (.*) ====$/, '<h4>\1</h4>')
    contents.gsub!(/^===== (.*) =====$/, '<h5>\1</h5>')

    # A hackish way to do paragraphs.
    # This is here and not earlier because it'll interfere with the listing functionality.
    contents.gsub!(/(\n\n)/, '</p>\1<p>')

    create_file(target_file_full_path, contents)
    tidy_html(target_file_full_path)

    # TODO: sync the timestamp, this would probably work:
    # timestamp_sync(source_file_full_path, target_file_full_path)

  end
  compile(source_file_full_path, target_file_full_path)
end
def test_compile()
  contents=<<-HEREDOC
If this appears with lots of square boxes through it, or lines are being merged together oddly, then TidyHTML was probably not installed.
  
*bold*, **big**. _underline_ /italics/ -strikethrough- `truetype`

Yes, this is legal in my code.  I'll just clean it up with HTML Tidy.:

  *two _words* test_

* _bold underline_ * _ *underline bold* _ _ * / underlined bold emphasis / * _

` ** * - _ / big bold strikethrough underlined emphasis truetype / _ - * ** `

FIXME:
left <a href="http://link.com">no *markup* here</a> right

<nowiki>*test*</nowiki>  <anything>_yep_</> <>don't</>

left http://link.com right

http://nolink http://nolink.c

http://link.ca

http://link.com

ftp://link.ca

*bold*._notunderlined_

---

Testing automatic link generation.  Local files become keywords.  Within any source text, those keywords become links.  Testing 'some' 'some example' 'example'.
Expecting:
1) FIXME: one complete link:  some example
2) two separate links:  some, then example

this is some example text in *an _ example _ paragraph*

this is some text

this is someexample text

this issome example text

FIXME <a href="http://example.com">test</a> - broken because example is a file-link.

FIXME http://example.com
  HEREDOC

  working_directory=File.join('', 'tmp', "test_markup.#{$$}")
  md_directory(working_directory)

  create_file(File.join(working_directory, "some.asc"), "")
  create_file(File.join(working_directory, "some example.asc"), "")
  create_file(File.join(working_directory, "example.asc"), "")

  source_file=File.join(working_directory, 'source.asc')
  create_file(source_file, contents)

  compile(source_file, working_directory)

  target_file_full_path=File.join(working_directory, File.basename(source_file.chomp(File.extname(source_file))) + '.html')
  puts file_read(target_file_full_path)
  view_html(target_file_full_path)
end
# $VERBOSE=nil
#test_compile()
# clean up the working directories with something like:
# rm -rf /tmp/test_markup.???? /tmp/test_markup.????

def generate_sitemap(directory)
  def sanity_check(directory)
    # TODO
  end
  #sanity_check(directory)
  contents=[]
  Dir["#{directory}/*"].each do |file|
    next if not File.file?(file)
    file=File.basename(file)
    contents << '<a href="' + file + '">' + file + '</a><br>' + "\n"
  end
  contents.sort!
  sitemap_file=File.join(directory, 'sitemap.html')
  create_file(sitemap_file, contents)
  tidy_html(sitemap_file)
end
#generate_sitemap(compiled_directory)

def main(source_directory, compiled_directory)
  def process(source_file_full_path, target_file_full_path)
    compile(source_file_full_path, target_file_full_path)
    timestamp_sync(source_file_full_path, target_file_full_path)
    view_html(target_file_full_path)
    # TODO: Re-compile all files in that same source directory, to ensure that automatic linking is re-applied to include this new file
  end
  pid_file=File.join('', 'tmp', 'compile_child_pid')
  fork_killer(pid_file)
  cd_directory(source_directory)
  # The main loop - once a second.
  fork_helper(pid_file) {
    Dir['**/*.asc'].each do |asc_file|
      target_file_full_path=File.expand_path(File.join(compiled_directory, asc_file.chomp('.asc') + '.html'))
      source_file_full_path=File.expand_path(asc_file)
      if not File.exists?(target_file_full_path) then
        vputs 'Building missing file:  ' + source_file_full_path.inspect
        vputs ' ...             into:  ' + target_file_full_path.inspect
        process(source_file_full_path, target_file_full_path)
        # TODO: Re-generate the sitemap, so that this new item will be created.
        generate_sitemap(File.dirname(target_file_full_path))
        next
      end
      source_time=File.stat(source_file_full_path).mtime
      target_time=File.stat(target_file_full_path).mtime
      if not source_time == target_time then
        target_path=File.join(compiled_directory, File.dirname(asc_file))
        vputs 'Building unsynced timestamps:  ' + source_file_full_path.inspect
        vputs ' ...                    with:  ' + target_file_full_path.inspect
        process(source_file_full_path, target_file_full_path)
        next
      end
    end # Dir['**/*.asc'].each
  } # fork_helper
end # main

$VERBOSE=nil

main(source_directory, compiled_directory)
# sleep 1
# viewer(File.join(target_directory_path, 'index.html'))
# sleep 3
# fork_killer(File.join('', 'tmp', 'compile_child_pid'))


