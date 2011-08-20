=begin
Usage:
- You can combine multiple markup by starting it all with spaces between them.
- wiki-style linking is done automatically, just type as usual and the engine will figure out the links.  Note that multiple words are given priority over single words.

Requirements:
- Ruby 1.8.7 and its standard libraries
- My standard libraries
- HTML Tidy (the executable, not the Ruby library)
  http://tidy.sourceforge.net/

  # Tested and works on Unity Linux 64bit as of 2010-04-25:
  cvs -d:pserver:anonymous@tidy.cvs.sourceforge.net:/cvsroot/tidy login
  # press enter
  cvs -z3 -d:pserver:anonymous@tidy.cvs.sourceforge.net:/cvsroot/tidy co -P tidy
  cd tidy/build/gmake
  make
  su
  smart install libxslt-proc
  make install
=end

# No trailing slashes
# The directory with the original .asc files
source_directory='source'
# The directory with the cached hybrid asc-html files:  asc-markup => html-markup
# The directory with the completed html files
compiled_directory='compiled'
# TODO: A variable for the web browser?  Seems non-obvious..
# To customize the browser that's used, hack view_html()

source_directory=File.expand_path(File.join(File.dirname(__FILE__), '..', source_directory))
compiled_directory=File.expand_path(File.join(File.dirname(__FILE__), '..', compiled_directory))

require 'pathname'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'lib_misc.rb'
require 'lib_directories.rb'
require 'lib_files.rb'
require 'lib_strings.rb'

# [:punct:] and [:blank:] don't work..
$punctuation_start=%r{
  ^
  |^'
  |\ '
  |^"
  |\ "
  |\ 
  |\ \(
  |^\(
  |>
}x
# Note that something like 'oldschool-linux.asc' won't get linked, because this regular expression requires an ending like '. '
#   A simple '|\.' can be added to relax this restriction.
$punctuation_end=%r{
  $
  |\.\ 
  |,\ 
  |!\ 
  |'$
  |'\ 
  |',
  |,'
  |"$
  |"\ 
  |",
  |,"
  |\ 
  |\)\ 
  |\)$
  |<
}x

def sanity_check(source_directory, compiled_directory)
  # TODO: Confirm that tidy exists and can be run.
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
      raise "\n * There's a file where I'm expecting your source_directory:\n" + source_directory.inspect
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
      raise "\n * There's a file where I'm expecting your compiled_directory:\n" + compiled_directory.inspect
      abort
    end
  end
end
sanity_check(source_directory, compiled_directory)

# TODO:  Implement a wmctrl thingy to raise the firefox window.  But apparently it's not possible!!
# http://localhost/wiki/Wmctrl_examples#Firefox_is_not_visible_in_the_list_of_managed_windows
def view_html(file_full_path)
  if File.exists?(file_full_path) then
    # Note: For a browser to work as expected, I'd have to already have it running before this script summons it.
    # Otherwise, this script would summon it wait for it to exit!
    #system('firefox', '-new-tab', file_full_path)
    system('firefox', file_full_path)
    # Does not respect accesskeys, it thinks that .asc is a PGP file.  Bah.
    # It also saves the .asc files to /tmp.. sigh.
    #system('midori', file_full_path)
    #system('links', '-g', file_full_path)
  else
    raise "\n * File does not exist, aborting:\n" + file_full_path.inspect
    abort
  end
end
def tidy_html(source_file_full_path)
  system('tidy', '--drop-empty-paras', 'true', '--indent', 'true', '--keep-time', 'true', '--wrap', '0', '-clean', '-quiet', '-omit', '-asxhtml', '-access', '-modify', '--force-output', 'true', '--show-errors', '0', '--show-warnings', 'false', '--break-before-br', 'true', '--tidy-mark', 'false', source_file_full_path)
end

def compile(source_directory, source_file_full_path, target_file_full_path)
  # TODO:  Only allow one document-link within each file?  I'd have to maintain a working array of all the already-created links, and know if I'm creating a duplicate.  Not too tough to do
  # TODO:  Allow additional document-links, but only one document-link for each header-section.  Somewhat more complex than the above, but really really worth it.

  def sanity_check(source_file_full_path, target_file_full_path)
    target_file_directory=File.dirname(target_file_full_path)
    if not File.exists?(source_file_full_path) then
      raise "\n * source_file_full_path does not exist, aborting:\n" + source_file_full_path.inspect
      abort
    elsif File.directory?(source_file_full_path) then
      raise "\n * source_file_full_path is a directory.  Expecting a file:\n" + source_file_full_path.inspect
      abort
    elsif File.directory?(target_file_full_path) then
      raise "\n * target_file_full_path is a directory.  Expecting a file:\n" + target_file_full_path.inspect
      abort
    elsif not File.directory?(target_file_directory) then
      puts "Target file's base directory does not exist.  Creating:  " + target_file_directory
      md_directory(target_file_directory)
    end
    # Future TODO:  If I ever do nested linking, I should make sure that the parent director(y|ies) exist.
  end
  sanity_check(source_file_full_path, target_file_full_path)
  def markup(string, search_left, search_right, replace_left, replace_right, internal_markup_flag)
    def marked_yes(string, search_left, search_right, replace_left, replace_right)
      if string == nil or string == '' then return '' end
      # TODO: If a link, check that the destination exists
      #  - local = create the file
      #  - remote = check if it exists, and cache the results?  Only check once a day?  Then I can redirect to a page if I know the link is bad, and create a notification to myself.. maybe updating a master status log file.
      if replace_left == nil and replace_right == nil then
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

    # TODO: This is the far cooler version which I should implement.
    #   It cannot work as-is because \1 doesn't carry through.
    #   So what I'd need to do is to completely tear out this markup() concept and redo things from a much simpler perspective.
    # Oh oh!  I could use whatever.dup and then use match[1] like I've done before.
    #[
      #['/', '<em>', '</em>'],
      #['*', '<b>', '</b>'],
      #['**', '<big>', '</big>'],
    #].each do |i|
      #i[0]=Regexp.quote(i[0])
      #string=markup(
        #string,
        #%r{(#{$punctuation_start})#{i[0]}},
        #%r{#{i[0]}(#{$punctuation_end})},
        #"\1#{i[1]}",
        #"#{i[2]}\1",
        #true
      #)
    #end

        # TODO: Strikethrough was removed because it interferes with lists, and I didn't feel like recoding everything to get this very rarely-used markup to work.
        #   But I will, eventually..
        #string=markup(string, %r{(#{$punctuation_start})-}, %r{-(#{$punctuation_end})}, '\1<s>', '</s>\1', true)
        string=markup(string, %r{(#{$punctuation_start})\/}, %r{\/(#{$punctuation_end})}, '\1<em>', '</em>\1', true)
        string=markup(string, %r{(#{$punctuation_start})\*\*}, %r{\*\*(#{$punctuation_end})}, '\1<big>', '</big>\1', true)
        string=markup(string, %r{(#{$punctuation_start})\*}, %r{\*(#{$punctuation_end})}, '\1<b>', '</b>\1', true)
        string=markup(string, %r{(#{$punctuation_start})_}, %r{_(#{$punctuation_end})}, '\1<u>', '</u>\1', true)
        string=markup(string, %r{(#{$punctuation_start})`}, %r{`(#{$punctuation_end})}, '\1<tt>', '</tt>\1', true)
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
  # TODO: Should I replace these simple numbered anchors with the name of the header?  Then I'd have to clean up the header text to make it valid HTML.  Eww.
  def HTML_headers(string)
    regex=%r{
      ^([=]+)
      \ 
      ([^\ ].*?[^\=])
      (\ [=]+$|$)
    }x
    result=[]
    total=0
    $toc=[]
    string.each do |line|
      line =~ regex
      if $~ != nil then
        # count the number of = at the start of the header.
        n=($~[1].length).to_s
        total += 1
        prepend=if total > 1 then '</div>' else '' end
        section_link = '<a class="h-link" href="#a' + total.to_s + '"> &nbsp;&sect;&nbsp; </a>'
        line.sub!(regex, prepend + '<h' + n + ' class="h-link" id="a' + total.to_s + '">\2' + section_link + '</h' + n + '><div class="indent' + n + '">' + "\n")
        indent=''
        #($~[1].length).times do
          #indent=indent + '&nbsp;'
        #end
        indent='#' * ($~[1].length) + ' '
        $toc << "\n" + indent + '<a href="#a' + total.to_s + '">' + $~[2] + '</a>'
      end
      result << line
    end
    string=result.to_s
    # Note that I am *not* inserting $toc anywhere here.  That's the template/header's job.
    # Obsolete:  If there is a header, then remove the first </div> so that it won't close <div class="main">
    #string.sub!(/<\/div><h(\d)>/, '<h\1>')
    return string
  end
  def HTML_horizontal_rules(string)
    #   With an empty space above and below.
    string.gsub!(/\n\n\-\-\-+\n\n/m, '<hr>')
    #   With content either above or below.
    string.gsub!(/^\-\-\-+$/, '<hr class="small">')
    return string
  end
  def HTML_paragraphs(string)
    # This is a hackish way to do paragraphs.
    string.gsub!(/(\n\n)/, "\n</p>\1<p>\n")
    return string
  end
  # Plain links, like:  http://example.com (HTML link to its source)
  def links_rx()
    return %r{
      ( (?# http://)
         http:\/\/
        |https:\/\/
        |ftp:\/\/
        |irc:\/\/
        |gopher:\/\/
        |file:\/\/
      )
      ( (?# whatever.info)
        \S{2,}\.\S{2,4}
      )
      ( (?# /foo/bar.html)
         \/\S+[^\]]
        |[^\]]
      )
    }x
  end
  def links_plain(string)
    # Note that this also handles IP:Port, but it does no error correction.
    result=[]
    url = %r{
      (#{$punctuation_start})
      #{links_rx()}
      (#{$punctuation_end})
    }x
    result=[]
    string.each do |line|
      # Yes this is a bit odd, but because of the way regex works I cannot keep my punctuation start/end restrictions while matching two consecutive items which are separated by punctuation.  So ' one two ' ends up only matching ' one '
      until line.scan(url).size == 0 do
        # Without http://
        line.sub!(url, '\1<a href="\2\3\4">\3\4</a>\5')
        # If you want to show the http:// part as well:
        #line.sub!(url, '\1<a href="\2\3\4">\2\3\4</a>\5')
      end
      result << line
    end
    return result.to_s
  end
  # Named links, like:  [http://example.com name] => name (HTML link to its source)
  def links_named(string)
    # Note that this also handles IP:Port, but it does no error correction.
    url = %r{
      (#{$punctuation_start})
      \[
      #{links_rx()}
      \                (?# A space)
      (.+?[^\]])
      \]
      (#{$punctuation_end})
    }x

    result=[]
    string.each do |line|
      # Yes this is a bit odd, but because of the way regex works I cannot keep my punctuation start/end restrictions while matching two consecutive items which are separated by punctuation.  So ' one two ' ends up only matching ' one '
      until line.scan(url).size == 0 do
        line.sub!(url, '\1<a href="\2\3\4">\5</a>\6')
      end
      result << line
    end
    return result.to_s
  end
  # Numbered links, like:  [http://example.com] => [1] (HTML link to its source, and incrementally-counted)
  def links_numbered(string)
    # Note that this also handles IP:Port, but it does no error correction.
    url = %r{
      (#{$punctuation_start})
      \[
      #{links_rx()}
      \]
      (#{$punctuation_end})
    }x
    result=[]
    counter=0
    string.each do |line|
      until line.scan(url).size == 0 do
        counter += 1
        line.sub!(url, '\1<a href="\2\3\4">[' + counter.to_s + ']</a>\5')
      end
      result << line
    end
    return result.to_s
  end
  # TODO: Local links to new pages, like:  [[link name]] => 'link-name.asc'
  def TODO_links_local_new(string)
    url = %r{
      (#{$punctuation_start})
      (\[\[)
      (\S+)
      (\]\])
      (#{$punctuation_end})
    }x
    result=[]
    string.each do |line|
      line =~ url
      if $~ != nil then
        line_copy = line.dup
        line_copy.gsub!(url, '~~~~~url~~~~~')
        line_copy=line_copy.split('~~~~~url~~~~~')
        line_copy_length=(line_copy.length)-1
        line_copy_length.times do
          line =~ url
          match=$~.dup
# check for the file
## if exists, remove the [[ and ]] (from both this string and the source file) and then links_automatic() will catch it.
## if it does not exist, then make some sort of self-known local link to that file, so that clicking on it in a browser will open up an editor with that filename ready (displaying an empty file)
          line.sub!(url, " -> #{match[1]}#{match[3]}#{match[5]} <- ")
        end
      end
      result << line
    end
    return result.to_s
  end
  def links_automatic(source_file_full_path, string, directory)
    source_name=File.basename(source_file_full_path, '.asc')
    # Get the files in the present directory:
    array_files=[]
    Dir["#{directory}/*.asc"].each do |file|
      next if not File.file?(file)
      next if file == source_file_full_path
      # "/path/foo/file name.asc" => "file name"
      array_files << File.basename(file, '')
    end
    # This sort prioritizes multiple-word files ahead of single-word files.
    array_files.sort!

    file_working=[]
    string.each do |line|
      array_files.each do |file|
        file_string=file.chomp('.asc')
        file_url=file_string + '.html'
        # I'm being pretty cheap here.  Instead of being smart about auto-linking URLs, and intentionally avoiding odd broken-assed web+local links, I'm limiting what things can be auto-linked as local links.
        # Link the exact filename.
        line=markup(line, %r{(#{$punctuation_start})(#{file_string})(#{$punctuation_end})}i, //, '\1<a href="' + file_url + '">\2</a>\3', '', true)
        # Also be forgiving for punctuation like dashes.
        file_string.gsub!('-', ' ')
        line=markup(line, %r{(#{$punctuation_start})(#{file_string})(#{$punctuation_end})}i, //, '\1<a href="' + file_url + '">\2</a>\3', '', true)
      end
      file_working << line
    end
    return file_working.to_s
  end
  # TODO: This does not allow lists of mixed types (e.g. ordered within unordered)
  # TODO: Fucking totally overhaul this piece of shit..  I'm chopping off \n and it's screwing with stuff..
  def lists(string, regex, opening, closing, line_start, line_end, line_continuation)
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
  def mixed_lists(string)
    return string
  end
  def header_and_footer(string, source_directory, source_file_full_path)

if $toc == [] then $toc = ''
else
$toc=<<-"HEREDOC"
<script language="javascript">
  function toggle(targetId) {
    target = document.getElementById(targetId);
    if (target.style.display == ""){
      target.style.display="inline";
    } else if (target.style.display == "none"){
      target.style.display="inline";
    } else {
      target.style.display="none";
    }
  }
</script>
<div id="toc-main">
  <small><a accesskey="t" href="javascript:toggle('toc')">Table of Contents</a></small>
  <div id="toc" style="display: none">
    #{$toc}
  </div>
</div>
HEREDOC
end

    a=Pathname.new(source_directory)
    b=Pathname.new(File.dirname(source_file_full_path))
    path=a.relative_path_from(b)
    header_search = Regexp.new('')
    header_replace=<<-"HEREDOC"
      <link rel="icon" href="#{path}/images/favicon.ico" type="image/x-icon">
      <link rel="shortcut icon" href="#{path}/images/favicon.ico" type="image/x-icon">
      <link rel="stylesheet" type="text/css" href="#{path}/css/main.css" />
      <title>#{File.basename(source_file_full_path, '.asc')}</title>
    </head>
    <body>
      <a name id="top">
      <div class="nav">
        <div class="float-left">
          <a accesskey="z" href="#{path}/index.html">
            <img align="left" src="#{path}/images/spiralofhope-96.png">
          </a>
          <br>
          <font style="font-size:1.5em;"><font color="steelblue">S</font>piral of Hope</font>
          <br>
          <font style="font-size: 0.5em;">Better software is possible.</font>
        </div>
        <div class="float-right">
          <form action="http://www.google.com/search">
            <input class="edit-line" name="q" size="25" accesskey="f" value="Search" class="texta" />
            <input type="hidden" name="sitesearch" value="spiralofhope.com" />
          </form>
          #{$toc}
        </div>
      </div>
      <a name="body">
      <div class="main">
    HEREDOC

=begin
I simplified it, here's the original:
<form method="get" action="http://www.google.com/search">
<input type="text" name="q" size="25" maxlength="255" accesskey="f" value="Search" />
<input type="submit" value="Search" />
<input type="hidden" name="sitesearch" value="spiralofhope.com" />
=end
    # '~~~~FOOTER~~~~' is a totally hackish thing for me to do, but oh well.
    # Could I search for the EOF or something cool?  Or just.. directly append this to do the bottom perhaps.
    footer_search=Regexp.new('~~~~FOOTER~~~~')
    puts footer_search
    # The top </div> will close any remaining <h1 class="indent1"> type references.  HTML Tidy will clean things up if there are no headers on that page.
    # Close the div created by the last header, if there was one.
    if $toc != '' then
      footer_replace = '</div>'
    else
      footer_replace = ''
    end
    footer_replace+=<<-"HEREDOC"
  </div> <!-- main -->
  <div class="footer">
    &copy; <a href="#{path}/contact.html">Spiral of Hope</a> - all rights reserved (until I figure licensing out)
    <br>
    <!-- TODO -->
    <img border="0" src="#{path}/images/FIXME.png">Hosting provided by (FIXME), <a href="#{path}/thanks.html#FIXME">thanks!</a>
    <br>
    <em><small>(<a href="#{path}/sitemap.html">sitemap</a>)</small></em>
    <br>
    <a style="display: none;" accesskey="e" href="file://#{source_file_full_path}">&nbsp;</a>

<!-- Start of StatCounter Code -->
<script type="text/javascript">
var sc_project=4910069;
var sc_invisible=1;
var sc_partition=57;
var sc_click_stat=1;
var sc_security="1ce5ea53";
</script>

<div id="statcounter_image"
style="display:inline;"><a title="web stats"
class="statcounter"
href="http://www.statcounter.com/free_web_stats.html"><img
src="http://c.statcounter.com/4910069/0/1ce5ea53/1/"
alt="web stats"
style="border:none;"/></a></div>

  </body>
</html>
HEREDOC

    string=multiline_replace(header_search, string, header_replace)
    string=multiline_replace(footer_search, string, footer_replace)
    return string
  end
  
  def compile(source_directory, source_file_full_path, target_file_full_path)
    contents=file_read(source_file_full_path)

    # Note that the order of this stuff *is* important.

    contents=markup(contents, /<.+>/, /<.+>/, nil, nil, false)

    # Horizontal rules
    contents=HTML_horizontal_rules(contents)

    # Paragraphs
    contents=HTML_paragraphs(contents)

    # Unordered lists
    # FIXME: This is really fragile stuff, and doesn't like being moved around within compile()
    #   FIXME:  FUCK, it's interacting with the strikethrough feature!
    contents=lists(contents, %r{^(-+) (.*)$}, '<ul>', "</ul>\n", '<li>', ' </li>', '')
    # Ordered lists
    contents=lists(contents, %r{^(#+) (.*)$}, '<ol>', "</ol>\n", '<li>', ' </li>', '')
    # Indentation
    #   FIXME:  Doesn't allow nested indented items.  So two colons doesn't double-indent.
    contents=lists(contents, %r{^(:+) (.+)$}, '<dl>', "</dl>\n", '<dd>', ' </dd>', '')
    # Code blocks
    contents=lists(contents, %r{^( )(.*)$}, '<pre>', "</pre>\n", '', '', ' <br>')

    contents=mixed_lists(contents)

    # Links
    contents=links_plain(contents)
    contents=links_named(contents)
    contents=links_numbered(contents)
    # TODO
    #contents=links_local_new(contents)
    contents=links_automatic(source_file_full_path, contents, File.dirname(source_file_full_path))

    # Headers (<h1> etc) and table of contents preparation
    contents=HTML_headers(contents)

    # TODO: '~~~~FOOTER~~~~' is a totally hackish thing for me to do, but oh well.
    #   I should just redo this to make it a simple header + contents + footer.. eesh.
    # And table of contents insertion.
    contents=header_and_footer(contents + '~~~~FOOTER~~~~', source_directory, source_file_full_path)
    # Re-generate ordered lists, so that a table of contents can be generated.
    if $toc != '' then
      contents=lists(contents, %r{^(#+) (.*)$}, '<ol>', "</ol>\n", '<li> ', '</li>', '')
    end

    create_file(target_file_full_path, contents)
    tidy_html(target_file_full_path)
    timestamp_sync(source_file_full_path, target_file_full_path)

  end
  compile(source_directory, source_file_full_path, target_file_full_path)
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

  compile(source_directory, source_file, working_directory)

  target_file_full_path=File.join(working_directory, File.basename(source_file.chomp(File.extname(source_file))) + '.html')
  puts file_read(target_file_full_path)
  view_html(target_file_full_path)
end
# $VERBOSE=nil
#test_compile()
# clean up the working directories with something like:
# rm -rf /tmp/test_markup.???? /tmp/test_markup.????

def generate_sitemap(directory, source_directory, source_file_full_path)
  def sanity_check(directory)
    # TODO
  end
  #sanity_check(directory)
  contents=[]
  Dir["#{directory}/*"].each do |file|
    next if not File.file?(file)
    file=File.basename(file)
    contents << '<li><a href="' + file + '">' + file + '</a></li>' + "\n"
  end
  contents.sort!

  a=Pathname.new(source_directory)
  b=Pathname.new(File.dirname(source_file_full_path))
  path=a.relative_path_from(b)
  footer=<<-"HEREDOC"
    <a class="without_u" accesskey="z" href="#{path}/index.html">
  HEREDOC
  contents.unshift('<ol>')
  contents << footer + "\n</ol>"

  sitemap_file=File.join(directory, 'sitemap.html')
  create_file(sitemap_file, contents)
  tidy_html(sitemap_file)
end
#generate_sitemap(compiled_directory)

def main(source_directory, compiled_directory)
  def process(source_directory, source_file_full_path, target_file_full_path)
    compile(source_directory, source_file_full_path, target_file_full_path)
    timestamp_sync(source_file_full_path, target_file_full_path)
    view_html(target_file_full_path)
    # TODO/FIXME: Re-compile all files in that same source directory, to ensure that automatic linking is re-applied to include this new file
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
        process(source_directory, source_file_full_path, target_file_full_path)
        generate_sitemap(File.dirname(target_file_full_path), source_directory, source_file_full_path)
        next
      end
      source_time=File.stat(source_file_full_path).mtime
      target_time=File.stat(target_file_full_path).mtime
      if not source_time == target_time then
        target_path=File.join(compiled_directory, File.dirname(asc_file))
        vputs 'Building unsynced timestamps:  ' + source_file_full_path.inspect
        vputs ' ...                    with:  ' + target_file_full_path.inspect
        process(source_directory, source_file_full_path, target_file_full_path)
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
