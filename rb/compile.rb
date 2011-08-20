#!/usr/bin/env ruby

=begin
= Requirements =

- Ruby 1.8.7 and its standard libraries.
-- Tested briefly and it's heavily bugged on Ruby 1.9.2
- A few of my standard libraries.
- HTML Tidy (the executable, not the Ruby library)
  http://tidy.sourceforge.net/
- Not tested on Windows.
=end

def configuration()
  # Note: To customize the browser that's used, edit view_html() directly.
  # TODO: A variable for the web browser?  Seems non-obvious.

  # The directory with the original .asc files
  #   No trailing slashes
  $source_directory='source/wiki'
  # The directory with the completed html files
  $compiled_directory='compiled'

  # If true, every time a page change is detected, that page will be viewed in your browser.
  #$view_html=true

  # Uncomment for debugging
  #$VERBOSE=true

  # TODO:  This doesn't need to be a global variable.  Make it a method.
  # e.g. [http://example.com example] becomes
  #   <a href="http://example.com">example<sub><small>&raquo;</small></sub></a>
  $external_link_before=''
  $external_link_after=''
  #$external_link_before='&lsaquo;'
  #$external_link_after='&rsaquo;'
  #$external_link_after='<sub><small>&raquo;</small></sub>'
  # Using a combining character on top of a space.
  # http://en.wikipedia.org/wiki/Combining_character
  #$external_link_after=' &#x20EF;'

  # TODO:  This doesn't need to be a global variable.  Make it a method.
  # e.g. [http://example.com] becomes
  #   <a href="http://example.com">[1]</a>
  $numbered_link_before='['
  $numbered_link_after=']'
  #$numbered_link_before='&lsaquo;'
  #$numbered_link_after='&rsaquo;'
end
configuration()


def internal_setup()
  $source_directory  =File.expand_path(File.join(File.dirname(__FILE__), '..', $source_directory  ))
  $compiled_directory=File.expand_path(File.join(File.dirname(__FILE__), '..', $compiled_directory))

  require 'pathname'
  lib_dir = File.join(File.dirname(__FILE__), 'lib')
  $LOAD_PATH.unshift(lib_dir)

  if $VERBOSE == true || $VERBOSE == nil then puts "Checking for library files:" end
  Dir[File.join(lib_dir, 'lib_*.rb')].each do |file|
    if $VERBOSE == true || $VERBOSE == nil then puts "\t#{file}" end
    require file
  end

  require File.join(File.dirname(__FILE__), 'header_and_footer.rb')

  # [:punct:] and [:blank:] don't work..
  $punctuation_start=%r{
    ^       (?# Line start)
    |\      (?# Space)
  }x
  $punctuation_start=%r{
    #{$punctuation_start}
    |#{$punctuation_start} '
    |#{$punctuation_start} "
    |#{$punctuation_start} \(
    |#{$punctuation_start} --
  }x
    
  $punctuation_end=%r{
    $     (?# Line end)
    |\    (?# Space)
  }x
  $punctuation_end=%r{
    #{$punctuation_end}
    |\.   #{$punctuation_end}
    |,    #{$punctuation_end}
    |!    #{$punctuation_end}
    |:    #{$punctuation_end}
    |;    #{$punctuation_end}
    |\?   #{$punctuation_end}
    |--   #{$punctuation_end}
    |'    #{$punctuation_end}
    |"    #{$punctuation_end}
  }x
  $punctuation_end=%r{
    #{$punctuation_end}
    |s    #{$punctuation_end}
    |es   #{$punctuation_end}
    |ed   #{$punctuation_end}
  }x
end
internal_setup()


def sanity_check(source_directory, compiled_directory)
  # TODO: Move this into lib_exec.rb somehow.  My experiments have failed so far.  I don't want the command attempt to output anything unless it's not found.
  def sanity_check_tidy()
    # Note that this method is nice and clean and doesn't output anything from the command.  Yay!
    result = `tidy -h`
    if $? != 0 then
      raise "\n * `tidy` was not found on this system.\n   I got status code: #{$?}\n   With the text:\n#{result}"
    end
  end
  sanity_check_tidy()

  sanity_check_directory(source_directory)
  sanity_check_directory(compiled_directory)
end
sanity_check($source_directory, $compiled_directory)


def view_html(file_full_path)
  # TODO:  Implement a wmctrl thingy to raise the firefox window.  But apparently it's not possible!!
  # http://localhost/wiki/Wmctrl_examples#Firefox_is_not_visible_in_the_list_of_managed_windows
  if $view_html != true || $view_html == nil then
    return 0
  end

  if File.exists?(file_full_path) then
    # Note: For a browser to work as expected, I'd have to already have it running before this script summons it.
    # Otherwise, this script would summon it and then wait for it to exit!
    #system('firefox', '-P', '-default', '-new-tab', file_full_path)
    system('firefox-4.0', '-profile', 'default', '--no-remote' , file_full_path)

    # Midori does not respect accesskeys, it thinks that .asc is a PGP file.  Bah.
    # It also saves the .asc files to /tmp.. sigh.
    #system('midori', file_full_path)

    # This will open the initial links window open.  Then somehow the script hangs and waits for links to be exited.
    #system('links', '-g', file_full_path)
  else
    raise "\n * File does not exist, aborting:\n" + file_full_path.inspect
    abort
  end
end


def tidy_html(source_file_full_path)
  # For additional options, check out `tidy -help-config`
  system(
    'tidy',
    '-clean',
    '-quiet',
    '-omit',
    '-asxhtml',
    '-access',
    '-modify',
    '--drop-empty-paras', 'true',
    '--indent', 'true',
    '--indent-spaces', '2',
    '--keep-time', 'true',
    '--wrap', '0',
    '--force-output', 'true',
    '--show-errors', '0',
    '--show-warnings', 'false',
    '--break-before-br', 'true',
    '--tidy-mark', 'false',
    '--output-encoding', 'utf8',
    '--escape-cdata', 'false',
    '--indent-cdata', 'true',
    '--hide-comments', 'true',
    '--join-classes', 'true',
    '--join-styles', 'true',
    source_file_full_path
  )
end


def compile(source_directory, source_file_full_path, target_file_full_path, type)
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
  # TODO: expand this or make a new procedure which can do search/replace only in the *middle*.  This is needed to fix links_automatic() so it works with files with spaces and hyphons.
  def markup(string, search_left, search_right, replace_left, replace_right, internal_markup_flag)
    def marked_yes(string, search_left, search_right, replace_left, replace_right)
      if string == nil or string == '' then return '' end
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
        string=markup(string, %r{(#{$punctuation_start}) \/   }x, %r{ \/   (#{$punctuation_end})}x, '\1<em>',  '</em>\1',  true)
        string=markup(string, %r{(#{$punctuation_start}) \*\* }x, %r{ \*\* (#{$punctuation_end})}x, '\1<big>', '</big>\1', true)
        string=markup(string, %r{(#{$punctuation_start}) \*   }x, %r{ \*   (#{$punctuation_end})}x, '\1<b>',   '</b>\1',   true)
        string=markup(string, %r{(#{$punctuation_start}) _    }x, %r{ _    (#{$punctuation_end})}x, '\1<u>',   '</u>\1',   true)
        string=markup(string, %r{(#{$punctuation_start}) `    }x, %r{ `    (#{$punctuation_end})}x, '\1<tt>',  '</tt>\1',  true)
        string=markup(string, %r{(#{$punctuation_start}) \^   }x, %r{ \^   (#{$punctuation_end})}x, '\1<sup>', '</sup>\1', true)
        # Curious, this interferes with = title, but none of this should respond in that manner.  I had to hack a solution.
        # Maybe this is showing a flaw in the way I'm doing things.
        string=markup(string, %r{(#{$punctuation_start})=([^ =])}, %r{=(#{$punctuation_end})}, '\1<sub>\2', '</sub>\1', true)
        internal_markup_flag=false
      end
      return string
    end

    processed=""
    # To avoid a runaway process, only handle 100 markup items on one single line:
    # TODO: Or maybe have a simple timer?
    count=0
    until string == nil or count > 100 do
      if count == 99 then puts "Found a line with too many matches, is something wrong?" end
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
    $paragraph = ''
    regex=%r{
      ^([=]+)
      \                (?# this is here to make sure there is a trailing space)
      ([^\ ].*?[^\=])
      (
         \ [=]+$
        |$
      )
    }x
    regex=%r{
      ^
      (=+)
      \ +
      (.+?)
      \ +
      =+
      $
    }x
    result=[]
    total=0
    $toc=[]
    string.each_line do |line|
      line =~ regex
      if $~ != nil then
        # count the number of equal signs at the start of the header.
        n=($~[1].length).to_s
        total += 1
        section_link = '<a class="h-link" href="#s' + total.to_s + '"> &nbsp;&sect;&nbsp; </a>'
        case n.to_i
          when 1 then
            paragraph = '<div class="p1">'
          when 2 then
            paragraph = '<div class="p1"><div class="p2">'
          when 3 then
            paragraph = '<div class="p1"><div class="p2"><div class="p3">'
          when 4 then
            paragraph = '<div class="p1"><div class="p2"><div class="p3"><div class="p4">'
          when 5 then
            paragraph = '<div class="p1"><div class="p2"> <div class="p3"><div class="p4"><div class="p5">'
          when 6 then
            paragraph = '<div class="p1"><div class="p2"><div class="p3"><div class="p4"><div class="p5"><div class="p6">'
          else ''
        end
        header = $paragraph + paragraph + '<h' + n + ' class="h-link" id="s' + total.to_s + '">\2' + section_link + '</h' + n + '>' + "\n"
        line.sub!(regex, header)
        indent=''
        indent='#' * ($~[1].length) + ' '
        $toc << "\n" + indent + '<a href="#s' + total.to_s + '">' + $~[2] + '</a>'
        case n.to_i
          when 1 then
            $paragraph = '<!----></div>'
          when 2 then
            $paragraph = '<!----></div><!----></div>'
          when 3 then
            $paragraph = '<!----></div><!----></div><!----></div>'
          when 4 then
            $paragraph = '<!----></div><!----></div><!----></div><!----></div>'
          when 5 then
            $paragraph = '<!----></div><!----></div><!----></div><!----></div><!----></div>'
          when 6 then
            $paragraph = '<!----></div><!----></div><!----></div><!----></div><!----></div><!----></div>'
          else ''
        end
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
    # This is a hackish way to do paragraphs:
    string.gsub!(/(\n\n)/, "\n</p><p>\n")
    # Allow multiple spaces to bleed through into the HTML:
    string.gsub!(/\n\n/, "<br>\n")
    return string
  end
  def links_rx()
    return %r{
      (?# http:// etc )
      (
         http:\/\/
        |https:\/\/
        |ftp:\/\/
        |irc:\/\/
        |gopher:\/\/
        |file:\/\/
      )
      (?# http://whatever.info  )
      (?# http://1.2.3.4 - also includes IPs, though I'm not sure how.  )
      (
         \S{2,}?\.\S{2,4}?
        | localhost
      )
      (?# FIXME:  Doesn't properly match http://example.com:1234 )
      (
         \/\S*[^\]]   (?# /foo/bar.html  )
        |[^\]]
      )
    }x
  end
  # FIXME: All of these links procedures have a potentially infinite looping issue.  If the regex matches, but the replace fails for some reason.  Harden it with either a catch/counter/throw, or a counter/raise.
  # Plain links, like:  http://example.com (HTML link to its source)
  def links_plain(string)
    result=[]
    url = %r{
      (#{$punctuation_start})
      #{links_rx()}
      (#{$punctuation_end})
    }x
    result=[]
    string.each_line do |line|
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
    string.each_line do |line|
      # Yes this is a bit odd, but because of the way regex works I cannot keep my punctuation start/end restrictions while matching two consecutive items which are separated by punctuation.  So ' one two ' ends up only matching ' one '
      until line.scan(url).size == 0 do
        line.sub!(url, '\1' + '<a href="\2\3\4">' + $external_link_before + '\5' + $external_link_after + '</a>\6')
      end
      result << line
    end
    return result.to_s
  end
  # Numbered links, like:  [http://example.com] => [1] (HTML link to its source, and incrementally-counted)
  def links_numbered(string)
    url = %r{
      (#{$punctuation_start})
      \[
      #{links_rx()}
      \]
      (#{$punctuation_end})
    }x
    result=[]
    counter=0
    string.each_line do |line|
      until line.scan(url).size == 0 do
        counter += 1
        line.sub!(url, '\1<a href="\2\3\4">' + $numbered_link_before + counter.to_s + $numbered_link_after + '</a>\5')
      end
      result << line
    end
    return result.to_s
  end
  # Local links to new pages, like:  [[link name]] => 'link-name.asc'
  def links_local_new(source_file_full_path, string)
    directory=File.dirname(source_file_full_path)
    result=[]
    regex = %r{
      (#{$punctuation_start})
      \[{2}
      ([^\[{2}].*?[^\]{2}])
      \]{2}
      (#{$punctuation_end})
    }x
    string.each_line do |line|
      if not line =~ regex then
        result << line
        next
      end
      until line.scan(regex).size == 0 do
        normalized_file=$~[2].gsub(' ', '-').downcase
        new_source_file_full_path = File.join(directory, normalized_file + '.asc')
        # Match [[file]] with /full/path/to/file.asc
        if File.exist?(new_source_file_full_path) and File.size(new_source_file_full_path) > 0 then
          # [[file]] is not actually new - it refers to an already-existing file, with content.
          # Remove the [[ and ]] from my current working string, and then links_automatic() will process this appropriately.
          line.sub!(regex, '\1\2\3')
          # Remove [[ ]] from the source file.
          # TODO: It's a bit of a waste to re-read/sub!/write this file every single time, and this needs to be optimised.
          new_contents=file_read(source_file_full_path)
          regex2 = %r{
            (#{$~[1]})
            \[{2}
            ((?-x)#{$~[2]}(?x))
            \]{2}
            (#{$~[3]})
          }x
          new_contents.sub!(regex2, '\1\2\3')
          create_file(source_file_full_path, new_contents)
        else
          # [[file]] is legitimately new.
          # Turn this into a link to create the file.
          # TODO: Make the 'a new' CSS (red on paragraph mouseover).
          # fixme: the filename shouldn't use spaces/etc.
          line.sub!(regex, '\1' + '<a class="new" href="file://' + new_source_file_full_path + '">\2</a>' + '\3')
          # Make a blank file so that I can link to an actually-existing file to summon my editor.
          if not File.exist?(new_source_file_full_path) then create_file(new_source_file_full_path, "") end
          #create_file(new_source_file_full_path, "")
        end
      end
      result << line
    end # string.each_line
    return result.to_s
  end
  # Magical automatic linking.  Ambrosia for authors.
  def links_automatic(source_file_full_path, string)
    source_name=File.basename(source_file_full_path, '.asc')
    # Get the files in the present directory:
    array_files=[]
    Dir[ File.join(File.dirname(source_file_full_path), '*.asc') ].each do |file|
      next if not File.file?(file)
      next if file == source_file_full_path
      # "/path/foo/file name.asc" => "file name"
      array_files << File.basename(file, '.asc')
    end
    # This sort prioritises multiple-word files ahead of single-word files.
    array_files.sort!.reverse!
    result=[]
    string.each_line do |line|
      array_files.each do |file|
        regex=%r{
          (#{$punctuation_start})
          (
             #{file}
            |(?-x)#{file.gsub('-', ' ')}(?x)
          )
          (#{$punctuation_end})
        }ix
        file_full_path=File.expand_path(file + '.asc')
        until line.match(regex) == nil or line.match(regex).size == 0 do
          if File.exist?(file_full_path) and File.size(file_full_path) > 0 then
# TODO: markup() or some new version should be used instead, so that this replace only happens outside of <a href= tags.
#   And then I'd have to remove my 'until line.match(regex).size == 0' concept.
#   Hell, I should only be linking one instance per section anyways.
            line.sub!(regex, '\1<a href="' + file + '.html">\2</a>\3')
          else
            line.sub!(regex, '\1<a class="new" href="' + file_full_path + '">\2</a>\3')
          end
        end
      end
      result << line
    end
    return result.to_s
  end
  # TODO: This does not allow lists of mixed types (e.g. ordered within unordered)
  # TODO: Fucking totally overhaul this piece of shit..  I'm chopping off \n and it's screwing with stuff..
  def lists(string, regex, opening, closing, line_start, line_end, line_continuation)
    result=[]
    previous_nesting=0
    # FIXME: This won't end correctly if the list ends with EOF.  Not a big deal since TidyHTML will probably fix it, but I should code this better.
    string.each_line do |line|
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

  def compile(source_directory, source_file_full_path, target_file_full_path, type)
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
    contents=lists(contents, %r{^(-+) (.*)$}, '<ul>', "</ul>\n", '<li> ', ' </li>' + "\n", '')
    # Ordered lists
    contents=lists(contents, %r{^(#+) (.*)$}, '<ol>', "</ol>\n", '<li> ', ' </li>' + "\n", '')
    # Indentation
    #   FIXME:  Doesn't allow nested indented items.  So two colons doesn't double-indent.
    contents=lists(contents, %r{^(:+) (.+)$}, '<dl>', "</dl>\n", '<dd> ', ' </dd>' + "\n", '')
    # Code blocks
    contents=lists(contents, %r{^( )(.*)$}, '<pre>', "</pre>\n", '', '', ' <br>')

    contents=mixed_lists(contents)

    # Links
    contents=links_plain(contents)
    contents=links_named(contents)
    contents=links_numbered(contents)
    contents=links_local_new(source_file_full_path, contents)
    contents=links_automatic(source_file_full_path, contents)

    # Headers (<h1> etc) and table of contents preparation
    contents=HTML_headers(contents)

    # TODO: '~~~~FOOTER~~~~' is a totally hackish thing for me to do, but oh well.
    #   I should just redo this to make it a simple header + contents + footer.. eesh.
    # And table of contents insertion.
    contents=header_and_footer(contents + '~~~~FOOTER~~~~', source_directory, source_file_full_path, type)
    # Re-generate ordered lists, so that a table of contents can be generated.
    if $toc != '' then
      contents=lists(contents, %r{^(#+) (.*)$}, '<ol>', "</ol>\n", '<li> ', '</li>', '')
    end

    create_file(target_file_full_path, contents)
    tidy_html(target_file_full_path)
    timestamp_sync(source_file_full_path, target_file_full_path)

  end
  compile(source_directory, source_file_full_path, target_file_full_path, type)

end


def generate_sitemap(directory, source_directory, source_file_full_path, type)
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

  case type
    when 'wiki' then
      footer=<<-"HEREDOC"
<a class="without_u" accesskey="z" href="#{path}/index.html">
HEREDOC
      contents.unshift('<ol>')
      contents << footer + "\n</ol>"
    when 'blog' then
      footer=<<-"HEREDOC"
<a class="without_u" accesskey="z" href="../#{path}/index.html">
HEREDOC
      contents.unshift('<ol>')
      contents << footer + "\n</ol>"
  end

  sitemap_file=File.join(directory, 'sitemap.html')
  create_file(sitemap_file, contents)
  tidy_html(sitemap_file)
end
#generate_sitemap(compiled_directory)


#def blog(source_directory, compiled_directory)
  #puts source_directory.inspect
  #puts compiled_directory.inspect
#end


def main(source_directory, compiled_directory)
  # TODO:  Check for an environment variable and use that.
  pid_file=File.join('', 'tmp', 'compile_child_pid')
  fork_killer(pid_file)


  def process(source_directory, source_file_full_path, target_file_full_path, type)
    compile(source_directory, source_file_full_path, target_file_full_path, type)
    timestamp_sync(source_file_full_path, target_file_full_path)
    view_html(target_file_full_path)
    # TODO/FIXME: Re-compile all files in that same source directory, to ensure that automatic linking is re-applied to include this new file
  end


  def check(source_directory, compiled_directory, type)
    case type
      when 'wiki' then
      when 'blog' then
        source_directory  =File.join(source_directory,   '..', 'blog')
        compiled_directory=File.join(compiled_directory,       'blog')
      else
        puts 'eek!'
    end
    if Dir.getwd != File.expand_path(source_directory) then
      # Yes, this keeps switching directories between the wiki and blog.  I don't need vputs to constantly tell me this.
      oldverbose=$VERBOSE
      $VERBOSE=false
      cd_directory(source_directory)
      $VERBOSE=oldverbose
    end
    # This was **/*.asc but I'm not going to look into subdirectories any more.
    Dir['*.asc'].each do |asc_file|
      target_file_full_path=File.expand_path(File.join(compiled_directory, asc_file.chomp('.asc') + '.html'))
      source_file_full_path=File.expand_path(asc_file)
      # Skip empty files.
      next if not File.size?(source_file_full_path)
      if not File.exists?(target_file_full_path)  then
        vputs ''
        vputs 'Building missing file:  ' + source_file_full_path.inspect
        vputs ' ...             into:  ' + target_file_full_path.inspect
        process(source_directory, source_file_full_path, target_file_full_path, type)
        generate_sitemap(File.dirname(target_file_full_path), source_directory, source_file_full_path, type)
        next
      end
      source_time=File.stat(source_file_full_path).mtime
      target_time=File.stat(target_file_full_path).mtime
      if not source_time == target_time then
        target_path=File.join(compiled_directory, File.dirname(asc_file))
        vputs ''
        vputs 'Building unsynced timestamps:  ' + source_file_full_path.inspect
        vputs ' ...                    with:  ' + target_file_full_path.inspect
        process(source_directory, source_file_full_path, target_file_full_path, type)
        next
      end
    end # Dir['*.asc'].each
  end


  # The main loop - once a second.
  fork_helper(pid_file) {
    check(source_directory, compiled_directory, 'wiki')
    check(source_directory, compiled_directory, 'blog')
  }
end # main


$VERBOSE=nil
main($source_directory, $compiled_directory)
# sleep 1
# viewer(File.join(target_directory_path, 'index.html'))
# sleep 3
# fork_killer(File.join('', 'tmp', 'compile_child_pid'))

__END__


=begin
None of this can work.  I *need* to do an intelligent search-and-replace leveraging my old markup() code.
Here's why:

Given 'foo', 'foo bar', 'baz foo bar quux', match against:
foo
foo bar
baz foo bar quux
I might currently get:
[[foo]]
[[foo]] bar
[[baz]] [[foo bar]] quux
I'm expecting:
[[foo]]
[[foo bar]]
[[baz foo bar quux]]

In order to solve this, I cannot do my 'until line.match(regex).size == 0' trick.  I must intelligently use markup() and only do the search-and-replace outside of the html <x>text</x> construct.
=end

$punctuation_start=%r{
  \     (?# this is here to make sure there is a trailing space)
}x
$punctuation_end=%r{
  \     (?# )
}x
["a line of foo text", "another foo - bar example"].each_line do |line|
  ["foo - bar", "foo"].each_line do |item|
    regex=%r{
      (
        (\ )
         #{item}
        |(?-x)#{item.gsub('-', ' ')}(?x)
        (\ )
      )
    }ix
puts line.inspect
puts item.inspect
#line.match(regex)
#puts $~.inspect
    counter=0
    until line.match(regex) == nil or line.match(regex).size == 0 or counter > 10 do
      line.sub!(regex, '\1<a href="' + item + '.html">\2</a>\3')
      counter += 1
    end
  end
  puts "---\n" + line.inspect
end
