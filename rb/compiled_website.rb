string = 'before <strong>some text <em>whoa</em> still</strong> NOT MARKUP <strong>here</strong> after'
#rx = %r{<([A-Z][A-Z0-9]*)\b[^>]*>.*?</\1>}
rx = %r{
  <                       (?# <html> )
  ([A-Za-z][a-zA-Z0-9]*)  (?# Valid html begins with a letter and then can have any combination of letters and numbers )
  \b                      (?# Word boundery -- I don't understand why this is here, but I'll keep it. )
  [^>]*
  >
  .*?                     (?# Anything:  .*  can be between the <html> and </html>, but don't be greedy:  ? )
  <                       (?# </html> where 'html' must match the earlier <html>. )
    /
    \1
  >
}x
#p string.match( rx )


def part( string, rx )
  a = [ string ]
  #rx = %r{<\S*?>.*?</\S*?>}
  #rx = %r{<\S*?>.*{1,1}?</\S*?>}
  a = a[-1].partition( rx )
  until a[-1].match( rx ) == nil do
    a = [ a[0..1], a[-1].partition( rx ) ].flatten
  end
  return a
end

string = 'before <strong>STRONG <em>STRONG-EMPHASIS</em> BOLD</strong> not markup <strong>STRONG</strong> after'
#left = '<>'
#right = '</>'
#string = string.split( %r{#{left}|#{right}} )

a = part( string, rx )

p string
a.each_index{ |i|
  printf( "%*s - %s \n", 2, i, a[i].inspect ) if i.odd?
  printf( "%*s - %s \n", 2, i, a[i].inspect ) if i.even?
}


#string.each_index{ |e|
#}


__END__

strings = [
 "bar:baz",
 "han:luke",
 "foo:foo"
]

# Only foo:foo will match
# Using back-references
strings.each do|s|
 if /((\w+):\2)/ =~ s
   puts "#{$1} #{$2}"
 end
end


__END__

# http://ruby.about.com/od/regularexpressions/a/lookback.htm
# lookahead
strings = [
 "start:bar",
 "start:baritone",
 "start:barbell",
 'nothing',
 'start:no',
]

start = 'start'
second_word = 'bar'
strings.each { |s|
 if s =~ /(#{start}):(?=#{second_word})(\w+)/
   puts "#{$1} #{$2}"
 end
}
# So what's happening here is that the (?=x) is modifying the (\w+) that comes after it, constraining it.
# (?=#{second_word})(\w+)

__END__




def merge_arrays( array1, array2 )
#puts "\n\n--v"
  result1 = [ array1[0] ]
  result2 = [ array2[0] ]
  array1.each_index { |i|
    next if i == 0
    if array1[i] == nil and result1[-1] == nil then
      result2[-1] << array2[i]
      next
    end
    if array2[i] == nil and result2[-1] == nil then
      result1[-1] << array1[i]
      next
    end
    if array1[i] != nil and result1[-1] == nil then
      result1 << array1[i]
      result2 << nil
      next
    end
    if array2[i] != nil and result2[-1] == nil then
      result2 << array2[i]
      result1 << nil
      next
    end
  }
#puts "--^\n\n"
  return result1, result2
end


def html_arrays2( string )
  if string.match( %r{<.*?>.*?</.*?>} ) == nil then
    html    = [ nil ]
    nonhtml = [ string ]
    return nonhtml, html
  end
  nonhtml = Array.new
  html    = Array.new

#puts "\n\n--v"

  string_original = string

  string.match( %r{(<.*?>)} )
     html << nil
  nonhtml << $`
  #
     html << $~[1]
  nonhtml << nil
  #
  string  =  $'
  nested  =  1

  until string == nil do
  
    string.match( %r{(<.*?>|</.*?>)} )
    if $~ == nil then
         html << nil
      nonhtml << string
      break
    end
    if nested > 0 then
            html << $`
         nonhtml << nil
    else
         html << nil
      nonhtml << $`
    end
    
       html << $~[1]
    nonhtml << nil
    string = $'
  
    open_or_close_tag = $~[1]
  
    if    open_or_close_tag.match( %r{ <.*?>}x ) != nil
      nested += 1
    elsif open_or_close_tag.match( %r{</.*?>}x ) != nil
      nested -= 1
    else
      # No closing tag was provided.  Eww.
    end
  
  end

html, nonhtml = merge_arrays( html, nonhtml )

#puts string_original.inspect
##puts html.inspect
##puts nonhtml.inspect

#html.each_index { |i|
#printf("%-*s   %s\n", 25, html[i].inspect, nonhtml[i].inspect)
##  printf("%*s   %s\n", 25, html[i].inspect, nonhtml[i].inspect)
#}

#puts "--^\n\n"
  return nonhtml, html
end

string = 'before<>html</>after'
string = 'before<>html<>nested</>still</>after'
string = 'before <strong>some text <em>whoa</em> still</strong> NOT MARKUP <strong>here</strong> more'
p html_arrays2( string )[0]
#p html_arrays2( string )[1]


__END__


string = "nonhtml"
string = "<>html</>"
#string = "<1>html</2>"
left  = '<>'
right = '</>'
pattern = %r{(#{left}|#{right})}
result = Array.new
nesting = 0
holding = ''

left  = %r{<.*?>}
right = %r{</.*?>}

string = "0a1a2c3c4"
string = "123abc"
string = "abc"
left  = %r{a}
right = %r{c}
working = ''
string.scan( %r{(#{left}|#{right})} ){ |i|
  pre_match = $`
  match = $~[1] # also i[0]
  nesting_previous = nesting
  nesting += 1 if i[0] =~ left
  nesting -= 1 if i[0] =~ right
p "#{nesting_previous} -> #{nesting}"

  if    nesting_previous == 0 and nesting == 1 then
    result << pre_match
    result << match
  elsif nesting_previous == 1 and nesting == 0 then
    result[-1] << working
    working = ''
  else
    working << pre_match << match
  end
}

p result

__END__

string.scan( pattern ){ |i|
  if $~[1] == left then
    nesting += 1
  else
    nesting -= 1
  end
  if nesting > 0 then
    holding += $`
  end
  if nesting == 0 then
    result << $` + holding + $~[1]
    holding = ''
  end
}

p result


__END__



$slow = false
$a = false

=begin
# Markup that's doable but which I don't care about.
# <sup> - Superscript
# <sub> - Subscript

AWW FUCK..
my 1.0.5 html_arrays2 can properly handle nesting like:  <><>foo</>bar</>
I have to re-absorb that stuff and figure shit out properly..


obsolete my array merging concept, I'm just passing a method to use into not_in_html and it's spitting my string back out.

I cannot use multiple parameters for not_in_html().  This must be fixed so that I can properly universally use this functionality.



<pre> blocks cannot work as things stand.  This is because I'm doing this:
  one <>two</> three
=>
<pre>one </pre>
<>two</>
<pre> three</pre>
.. so this means that as I walk through the html-split array, I need to properly stitch things back together again!  argh.  Once this is figured out, I can use this same understanding on my markup code.. which doesn't re-markup stuff in html.


FIXME FIXME -- I already have some stuff <p foo=bar> type stuff being defined by the section functionality.
Therefore the paragraphing method doesn't have to do (some of?) that..


to do:
- ensure that nothing is done on html blocks.  Borrow that functionality from markup and use it on everything like lists, etc.  Remove that functionality from any other process that's using it and doesn't really need to.

- Build a test case for whole-document creation.
- HTML Tidy?
- automatic local linking
-- dealing with punctuation is a terrible slowdown.    test with  $slow = false
-- 'YouTube batch downloading' is linking to the non-existant page 'YouTube'.  Write a test case and fix.

- explore syntax highlighting
- explore sortable tables


I want to do:
  /[http://en.wikipedia.org/wiki/Kari_%28music%29 Kari]/
I currently have to do:
  / [http://en.wikipedia.org/wiki/Kari_%28music%29 Kari] /

I want to do:
  (/nobekan/)
I currently have to do:
  ( /nobekan/ )
to fix that, I should include ( and ) within my start/end regexes..


- "proper" footnoting/endnoting
-- The user creates [1] markers, manually incrementing the number.
-- The user creates matching [1] markers at the bottom of the section or the end of the page.
-- The system detects if the user put them at the bottom or end.
-- The system picks up all of the [1] markers and re-numbers them so they are in-order.  The foot/endnotes are also picked up and sorted the same way.
-- This allows a person to go [2] [1] [4] [3] and the system will freely correct everything.

http://en.wikipedia.org/w/index.php?title=List_of_Babylon_5_episodes
only links
http://en.wikipedia.org/w/index.php?title=List_of_Babylon_5_episod

some things are not valid in certain filesystems, like question marks, colons, slashes etc.  I could expand my horrifying regex work and allow all of that sort of thing..

when a new [[link]] is found to exist, the original document doesn't have its [[ and ]] removed.  Did I code that?


Failed list, d is nested twice, not once.
- a
-- b
--- c

- d


how come 'Babylon 5' can show an auto-link to 'Babylon 5 - The Gathering' but I cannot have one on 'Babylon 5 viewing order' ??

durp, don't allow multi-line markup.

=end



require File.join( File.dirname( __FILE__ ), 'compiled_website--header_and_footer.rb' )
# used in header_and_footer()
# require 'pathname'
# Used in class Test_Markup < MiniTest::Unit::TestCase
# http://bfts.rubyforge.org/minitest/
require 'minitest/autorun'
# used for FileUtils.mkdir_p
require 'fileutils'


# http://stackoverflow.com/questions/3772864/how-do-i-remove-leading-whitespace-chars-from-ruby-heredoc/4465640#4465640
class String
  # Bug-fixed:  If there is no indenting, this explodes.  I changed \s+ to \s*

  # Removes beginning-whitespace from each line of a string.
  # But only as many whitespace as the first line of text has.
  #
  # Meant to be used with heredoc strings like so:
  #
  # text = <<-EOS.unindent
  #   This line has no indentation
  #     This line has 2 spaces of indentation
  #   This line is also not indented
  # EOS
  #
  def unindent
    lines = Array.new
    each_line { |ln| lines << ln }

    first_line_ws = lines[0].match( /^\s*/ )[0]
    rx = Regexp.new( '^\s{0,' + first_line_ws.length.to_s + '}' )

    lines.collect { |line| line.sub( rx, "" ) }.join
  end
end


class Markup

  def split_string( string, rx_left, rx_right )
    # even = not matching
    # odd  =     matching

string = [ string ]
result = Array.new

string[-1].match( %r{(#{rx_left}|#{rx_right})} )

case $~[1]
  when rx_left
    nested += 1
  when rx_right
    nested -= 1
  else
    p 'error in split_string'
end
if nested == 1 then
  string[-1] =  $`
  string     << $~[0] + $'
end

#string     << $~[1] + $'
#string[-2]  = $`


p string

    return string
  end

  def split_string_into_an_alternating_html_and_nonhtml_array( string )
    return split_string_into_an_alternating_match_and_nomatch_array( string, %r{<.*?>.*?</.*?>}m )
  end

  # TODO:  The splat isn't working properly..
  def not_in_html( string, *splat )
    array = split_string_into_an_alternating_html_and_nonhtml_array( string )
    array.each_index { |i|
      next if i.odd?
      array[i] = yield( array[i], splat )
    }
    return array
  end


# ---


  def punctuation_rx( left_rx, right_rx )
    # This would need to be reworked if it should match across lines.  But I don't think it should!
    # TODO:  Match across [ and ] ?
    punctuation_start=(%r{
      ^       (?# Line start)
      |\      (?# Space)
    }x)
    punctuation_start=(%r{
       #{punctuation_start}
      |#{punctuation_start} '
      |#{punctuation_start} "
      |#{punctuation_start} \(
      |#{punctuation_start} --
    }x)
      
    punctuation_end=(%r{
      $     (?# Line end)
      |\    (?# Space)
    }x)
    punctuation_end=(%r{
            #{punctuation_end}
      |\.   #{punctuation_end}
      |,    #{punctuation_end}
      |!    #{punctuation_end}
      |:    #{punctuation_end}
      |;    #{punctuation_end}
      |\?   #{punctuation_end}
      |--   #{punctuation_end}
      |'    #{punctuation_end}
      |"    #{punctuation_end}
    }x)
    punctuation_end=(%r{
            #{punctuation_end}
      |s    #{punctuation_end}
      |es   #{punctuation_end}
      |ed   #{punctuation_end}
    }x)

    return %r{
      (#{punctuation_start})
      (#{left_rx})
      (.*?)
      (#{right_rx})
      (#{punctuation_end})
    }x
  end
  
  def punctuation_rx_single( rx )

      punctuation_start=(%r{
        ^       (?# Line start)
        |\      (?# Space)
      }x)
      punctuation_start=(%r{
         #{punctuation_start}
        |#{punctuation_start} '
        |#{punctuation_start} "
        |#{punctuation_start} \(
        |#{punctuation_start} --
      }x)
        
      punctuation_end=(%r{
        $     (?# Line end)
        |\    (?# Space)
      }x)
      punctuation_end=(%r{
              #{punctuation_end}
        |\.   #{punctuation_end}
        |,    #{punctuation_end}
        |!    #{punctuation_end}
        |:    #{punctuation_end}
        |;    #{punctuation_end}
        |\?   #{punctuation_end}
        |--   #{punctuation_end}
        |'    #{punctuation_end}
        |"    #{punctuation_end}
      }x)
      punctuation_end=(%r{
              #{punctuation_end}
        |s    #{punctuation_end}
        |es   #{punctuation_end}
        |ed   #{punctuation_end}
      }x)

      return %r{
        (#{punctuation_start})
        (#{rx})
        (#{punctuation_end})
      }mx
  end
  

  # TODO:  All of the work on 'nonhtml, html' should be pulled out of here and put into one universal thingy so it can be used by _everything_.
  def markup( string, left_rx, right_rx, left_replace, right_replace )
    string = split_string_into_an_alternating_html_and_nonhtml_array( string )
    rx = punctuation_rx( left_rx, right_rx )
    string.each_index { |i|
      next if i.odd?
      next if string[i].match( rx ) == nil
      string[i].sub!( rx, $~[1] + left_replace + $~[3] + right_replace + $~[5] )
      string[i] = split_string_into_an_alternating_html_and_nonhtml_array( string[i] )
      string.flatten!
    }
    return string.join
  end

  def markup_underline( string )
    return markup( string, %r{_}, %r{_}, '<u>', '</u>' )
  end

  def markup_strong( string )
    return markup( string, %r{\*}, %r{\*}, '<strong>', '</strong>' )
  end

  def markup_big( string )
    return markup( string, %r{\*\*}, %r{\*\*}, '<big>', '</big>' )
  end

  def markup_emphasis( string )
    return markup( string, %r{\/}, %r{\/}, '<em>', '</em>' )
  end

  def markup_truetype( string )
    return markup( string, %r{`}, %r{`}, '<tt>', '</tt>' )
  end

# Stuff that's possible but which I don't care about.
# <sup> - Superscript
# <sub> - Subscript

  # TODO:  Is there an elegant way for me to just iterate through all methods of a certain name?  markup_* ?
  def markup_everything( string )
    return (
      # Items lower down are performed first.
      # This is important for things like **big** being matched before *strong* .
      markup_truetype(
      markup_underline(
      markup_emphasis(
      markup_strong(
      markup_big(
        string
      )))))
    )
  end

  def sections_arrays( string )
    rx = %r{(^=+)(\ )()(.*?)()(\ )(=+$)}
    # returns two arrays:  nonhtml, html (nomatch, match)
    return match_new( string, rx, false )
  end

  def sections( string )
    nomatch, match = sections_arrays( string )
    heading_level = 0
    heading_level_previous = 0
    match.each_index do |i|
      next if match[i] == nil
      match[i].match( %r{(^=+)(\ )()(.*?)()(\ )(=+$)} )
      next if $~ == nil
      heading_level_previous = heading_level
      heading_level          = $~[1].length
      title = "<h#{heading_level}>" + $~[4] + "</h#{heading_level}>"
      match[i] = ""

      # The first section encountered does not have previous sections to close.
      if heading_level_previous == 0 then
        # But it is legal have the document's first section be larger than one.
        a = heading_level
        ( heading_level - heading_level_previous ).times do
          match[i] = "<div class=\"s#{a}\">" + match[i]
          a -= 1
        end
        match[i] += title
        next
      end

      # stayed the same
      if heading_level == heading_level_previous then
        # Close the previous section.
        # Begin a new section.
        match[i] = "</div><div class=\"s#{heading_level}\">" + title
        next
      end

      # If the heading level increased, then one or more additional sections must be declared.
      # No previous sections will be closed.
      if heading_level > heading_level_previous then
        a = heading_level
        ( heading_level - heading_level_previous ).times do
          match[i] = "<div class=\"s#{a}\">" + match[i]
          a -= 1
        end
        match[i] += title
        next
      end

      # If the heading level decreased, then
      # 1) we must </div> to close off the appropriate number of previous sections.
      # 2) we must begin this new section
      if heading_level < heading_level_previous then
        a = heading_level
        ( heading_level_previous - heading_level + 1 ).times do
          match[i] = '</div>' + match[i]
        end
        match[i] = match[i] + "<div class=\"s#{heading_level}\">" + title
        next
      end

    end # match.each_index do |i|

    # Close off previous sections, if any.
    if heading_level > 0 then
      heading_level.times do
        nomatch[-1] += '</div>'
      end
    end

    return match, nomatch
  end # def sections( string )

  def paragraphs( string )
    # TODO:  There's probably another way to do this, but a (2..10).each construct wasn't playing nice.
    string.gsub!( /\n{10}/, "</p>\n#{"<br />\n" * 8}<p>" )
    string.gsub!( /\n{9}/,  "</p>\n#{"<br />\n" * 7}<p>" )
    string.gsub!( /\n{8}/,  "</p>\n#{"<br />\n" * 6}<p>" )
    string.gsub!( /\n{7}/,  "</p>\n#{"<br />\n" * 5}<p>" )
    string.gsub!( /\n{6}/,  "</p>\n#{"<br />\n" * 4}<p>" )
    string.gsub!( /\n{5}/,  "</p>\n#{"<br />\n" * 3}<p>" )
    string.gsub!( /\n{4}/,  "</p>\n#{"<br />\n" * 2}<p>" )
    string.gsub!( /\n{3}/,  "</p>\n#{"<br />\n" * 1}<p>" )
    string.gsub!( /\n{2}/,  "</p>\n#{"<br />\n" * 0}<p>" )
    return '<p>' + string + '</p>'
  end

  def HTML_horizontal_rules( string )
    #   With an empty space above and below.
    string.gsub!( /\n\n\-\-\-+\n\n/m, "\n\n<hr>\n\n" )
    #   With content either above or below.
    string.gsub!( /^\-\-\-+$/, '<hr class="small">' )
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
      (
         \/\S*[^\]]   (?# /foo/bar.html  )
        |[^\]]
      )
    }x
  end

  def links_plain( string )
    rx = punctuation_rx( links_rx, %r{} )
    until string.match( rx ) == nil do
      # Without http://
      string.sub!( rx, '\1<a href="\3\4\5\6">\4\5\6</a>\7\8' )
      # If you want to show the http:// part as well:
      #string.sub!( rx, '\1<a href="\3\4\5\6">\3\4\5\6</a>\7\8' )
    end
    return string
  end

  def links_named( string )
    rx = %r{
      \[
      #{ links_rx() }
      \                (?# A space)
      (.+?[^\]])
      \]
    }x
    rx = punctuation_rx( rx, %r{} )

    until string.match( rx ) == nil do
      string.sub!( rx, '\1<a href="\3\4\5">\6</a>\7\8\9' )
    end
    return string
  end

  def links_numbered( string, before, after, inside_before, inside_after, counter )
    rx = %r{
      \[{1}
      #{ links_rx() }
      \]{1}
    }x
    rx = punctuation_rx( rx, %r{} )
    until string.match( rx ) == nil do
      counter += 1
      string.sub!( rx,
        '\1' +
        before +
        '<a href="\3\4\5">' +
        inside_before +
        counter.to_s +
        inside_after +
        '</a>' +
        after + 
        '\7\8\9'
        )
    end
    return string, counter
  end

  def links_automatic( string, source_file_full_path )
#puts "\n\n--v"
    files_array = Dir[ File.dirname( source_file_full_path ) + '/*.asc' ]
    files_array.each_index { |i|
      next if files_array[i] == source_file_full_path
      next if File.file?( files_array[i] ) != true
      # This stuff is to make it so that only the first match is replaced.
      matched = false

      # 'one two-three' => ['one', 'two', 'three']
      a = ''
      a = File.basename( files_array[i], '.asc' )
      a = a.split(%r{-| })

      # ['one', 'two', 'three'] => %r{one[-| ]two[-| ]three}
      rx = %r{#{a[0]}}i
      a.each_index { |i|
        next if i == 0
        rx = %r{#{rx}[-|\ ]#{a[i]}}i
      }

if $slow == true then
      rx = punctuation_rx_single( rx )
else
      rx = %r{()(#{rx})()}
end

      words_to_match = File.basename( files_array[i], '.asc' ).gsub( '-', ' ' ).downcase
      nonhtml, html = html_arrays( string )

      nonhtml.each_index { |i|
        next if nonhtml[i] == nil
        next if nonhtml[i] == ""
        next if nonhtml[i] == " "
        next if nonhtml[i] == "\n"
        next if matched    == true

        if nonhtml[i].sub!(
          %r{#{rx}}i,
          '\1<a href="' + words_to_match.gsub( ' ', '-' ) + '.html">\2</a>\3'
        ) == nil then
          matched = false
        else
          matched = true
        end
      }
      string = recombine( nonhtml, html ).join
    }
#puts "--^\n\n"
    return string
  end

  # Local links to new pages, like:  [[link name]] => 'link-name.asc'
  def links_local_new( string, source_file_full_path )
    rx = %r{
      \[{2}
      ([^\[{2}].*?[^\]{2}])
      \]{2}
    }x
    rx = punctuation_rx( rx, %r{} )
    until string.match( rx ) == nil do
      # Is this good on Windows?
      new_source_file_full_path = File.join(
        File.dirname( source_file_full_path ),
        $~[3].gsub( ' ', '-' ).downcase,
      ) + '.asc'

      # Match [[file]] with /full/path/to/file.asc
      if File.exist?( new_source_file_full_path ) and File.size( new_source_file_full_path ) > 0 then
        # [[file]] is not actually new - it refers to an already-existing file, with content.
        # Remove the [[ and ]] from my current working string, and then links_automatic() will process this appropriately.
        string.sub!( rx, '\1\3\4\5\6' )
      else
        # [[file]] is legitimately new.
        # Turn this into a link to create the file.
        string.sub!( rx, '\1' + '<a class="new" href="file://' + new_source_file_full_path + '">\3</a>' + '\4\5\6' )
        # Make a blank file so that I can link to an actually-existing file to summon my editor.
        if not File.exists?( new_source_file_full_path ) then
          create_file( new_source_file_full_path, '' )
        end
      end # File.exist?( new_source_file_full_path ) and File.size( new_source_file_full_path ) > 0 then
    end # string.match( rx ) == nil do
    return string
  end

  def lists_arrays( string )
    rx = %r{^(\ *)([-|\#]+)(\ +)(.+)$}
    nomatch = Array.new
    match   = Array.new
    string = string.split( "\n" )
    string.each_index { |i|
      if string[i].match( rx ) == nil then
        if i == 0 then
          nomatch << string[i]
          match   << nil
          next
        end
        # If we're on a blank line, and the previous one was a match, and the next one is a match, append this \n to the previous match.
        # This allows a blank line between items of a list.
        # .gsub allows indentation
        if string[i].gsub( ' ', '' ) == '' and string[ i - 1 ].match( rx ) != nil and string[ i + 1 ] != nil and string[ i + 1 ].match( rx ) != nil then
          # This would keep a single \n if seen between list items.
          # match[-1] = match[-1] + "\n"
          next
        end
        # Just a regular line, begin a new element.
        nomatch << string[i]
        match   << nil
        next
      else # matched
        match_string = $~[2] + ' ' + $~[4]
        if i == 0 then
          nomatch << nil
          match   << match_string
          next
        end
        # If the previous one was a match
        if string[ i - 1 ].match( rx ) != nil then
          # append it
          match[-1] = match[-1] + "\n" + match_string
          next
        end
        # If the previous was a \n, and the previous-previous was a match
        # .gsub allows indentation
        if i > 1 and string[ i - 1 ].gsub( ' ', '' ) == '' and string[ i - 2 ].match( rx ) != nil then
          # append it
          match[-1] = match[-1] + "\n" + match_string
          next
        end
        # Just a plain old match, begin a new element.
        nomatch << nil
        match   << match_string
      end
    }

    # returns two arrays:  nonhtml, html (nomatch, match)
    return nomatch, match
  end

  def lists_initial_increase( two, string )
    close_tally = Array.new
    if    two[0] == '-' then
      c = 'u'
    elsif two[0] == '#' then
      c = 'o'
    end
    if two.length == 1 then
      open = "<#{c}l>\n<li>"
      close_tally << "\n</#{c}l>"
    else
      open = ( "<#{c}l>\n<li>\n" * two.length ).chomp
      two.length.times do
        close_tally << "\n</#{c}l>\n</li>"
      end
      close_tally[-1] = close_tally[-1].chomp("</li>").chomp
    end
    return open + string, close_tally
  end

  def lists_increase( two, string, delta, close_tally )
    if    two[0] == '-' then
      c = 'u'
    elsif two[0] == '#' then
      c = 'o'
    end
    open = "\n<#{c}l>\n<li>" * delta
    open = open[1..-1]
    delta.times do
      close_tally.insert( 0, "\n</#{c}l>\n</li>" )
    end

    return open + string, close_tally
  end

  def lists( string )
#puts "\n\n---v"
    notlists, lists = lists_arrays( string )
    rx = %r{^(\ *)([-|\#]+)(\ +)(.+)$}

#puts 'i:j   item      nesting type'
#puts '---   ----      ------- ----'


    lists.each_index { |i|
      next if lists[i] == nil
      current_list = lists[i].split( "\n" )
      close_tally = Array.new
      delta = 0
      previous_length = 0
      current_list.each_index { |j|
        current_list[j].match( rx )
#puts i.to_s + ':' + j.to_s + '  ' + current_list[j].inspect + "\t" + $~[2].length.to_s + "\t" + $~[2][0]

        if j == 0 then
          # The first line
          # On the first line I'm loading the delta variable so it can be properly used on later lines.
          close_tally = Array.new
          current_list[j], close_tally = lists_initial_increase( $~[2], $~[4] )
        else
          # Not on the first line
          delta = $~[2].length - previous_length
          if    delta == 0 then
            current_list[ j - 1 ] = current_list[ j - 1 ] + '</li>'
            current_list[ j     ] = '<li>' + $~[4]
          elsif delta >  0 then
            current_list[j], close_tally = lists_increase( $~[2], $~[4], delta, close_tally )
          elsif delta <  0 then
            current_list[ j - 1 ] = current_list[ j - 1 ] + '</li>' + close_tally.delete_at(0)
            current_list[ j     ] = '<li>' + $~[4]
          end
        end

        # If I'm at the end of the list.
        if current_list[ j + 1 ] == nil then
          current_list[-1] += '</li>' 
          close_tally.each { |e|
            current_list[-1] = current_list[-1] + e
          }
        end
        previous_length = $~[2].length
      } # j (a particular list)
      lists[i] = current_list.join( "\n" )
    } # i (the array of lists)
#puts "---^\n\n"
    return recombine( lists, notlists ).join( "\n" )
  end

  def blocks_arrays( string )
    match   = Array.new
    nomatch = Array.new
    c = 0
    string.each_line { |line|
      c += 1
      if line.match( %r{^\ } ) == nil then
        if nomatch[-1] == nil or c == 1 then
          match   << nil
          nomatch << line
        else
          nomatch[-1] += line
        end
      else
        if match[-1] == nil or c == 1 then
          match   << line
          nomatch << nil
        else
          match[-1] += line
        end
      end
    }
    return nomatch, match
  end

  def blocks( string )
    nomatch, match = blocks_arrays( string )
    string = ''
    match.each_index { |i|
      if match[i] == nil then
        string << nomatch[i]
      else
        string << "<pre>"
        string << match[i].unindent
        string << "</pre>"
      end
    }    
    
    return string
  end

end # class Markup

# --
# TEST CASES
# --

class Test_Markup < MiniTest::Unit::TestCase

  def setup()
    @o = Markup.new
  end

  def test_split_string()
    rx_left  = %r{<.*?>}m
    rx_right = %r{</.*?>}m

    string = 'nothing'
    result = @o.split_string( string, rx_left, rx_right )
    assert_equal(
      string,
      result[0],
    )
    assert_equal(
      '1',
      result.size.to_s
    )

    string = '<>html</>'
    result = @o.split_string( string, rx_left, rx_right )
    assert_equal(
      '',
      result[0],
    )
    assert_equal(
      '<>html</>',
      result[1],
    )
    assert_equal(
      '2',
      result.size.to_s
    )

    #string = 'before <>one</> <>two</> after'
    #result = @o.split_string( string, rx_array )
#p string
#p result
    #assert_equal(
      #'before ',
      #result[0],
    #)
    #assert_equal(
      #'<>one</>',
      #result[1],
    #)
    #assert_equal(
      #' ',
      #result[2],
    #)
    #assert_equal(
      #'<>two</>',
      #result[3],
    #)
    #assert_equal(
      #' after',
      #result[4],
    #)

    #string = <<-heredoc.unindent
      #before
      #<>
      #one
      #</>
      #<>
      #two
      #</>
      #after
    #heredoc
    #result = @o.split_string( string, rx )
    #assert_equal(
      #( <<-heredoc.unindent
        #before
      #heredoc
      #),
      #result[0],
    #)
    #assert_equal(
      #( <<-heredoc.unindent
        #<>
        #one
        #</>
      #heredoc
      #).chomp,
      #result[1],
    #)
    #assert_equal(
      #"\n",
      #result[2],
    #)
    #assert_equal(
      #( <<-heredoc.unindent
        #<>
        #two
        #</>
      #heredoc
      #).chomp,
      #result[3],
    #)
    #assert_equal(
      #"\nafter\n",
      #result[4],
    #)

    ## Not supported!
    ##string = 'this is a test <>with <>complex</> html</>'
    ##string = '<foo bar="baz > quux">no</> yes </>no</>'

  end

  def xx_test_not_in_html()
    def not_in_html_test_method( string, *var2 )
      #if defined?(var2) then puts var2.inspect end
      #if var2 == [] then var2 = '' end
      #string = "{#{string}}" + var2[0..-1].join
      return '' if string == ''
      string = "{#{string}}"
      return string
    end

    assert_equal(
      '{one}',
      @o.not_in_html( 'one' ) { |i| not_in_html_test_method( i ) }.join,
    )
    assert_equal(
      '{one }<>two</>',
      @o.not_in_html( 'one <>two</>' ) { |i| not_in_html_test_method( i ) }.join,
    )
    assert_equal(
      '{one }<>two</>{ three}',
      @o.not_in_html( 'one <>two</> three' ) { |i| not_in_html_test_method( i ) }.join,
    )

    #result = @o.not_in_html( 'one <>two</> three <>four</> five' ) { |i| not_in_html_method( i ) }
    result = @o.not_in_html( 'one <>two</> three <>four</> five' ) { |i| not_in_html_test_method( i, 'hey' ) }
    assert_equal(
      '{one }',
      result[0]
    )
    assert_equal(
      '<>two</>',
      result[1]
    )
    assert_equal(
      '{ three }',
      result[2]
    )
    assert_equal(
      '<>four</>',
      result[3]
    )
    assert_equal(
      '{ five}',
      result[4]
    )
  end

  def xx_test_markup_underline()
    assert_equal(
      '<u>underlined</u>',
      @o.markup_underline( '_underlined_' ),
    )
    assert_equal(
      'one <u>two</u> three <u>four</u>',
      @o.markup_underline( 'one _two_ three _four_' ),
    )
    string = '<> _not underlined_ </>'
    assert_equal(
      string,
      @o.markup_underline( string ),
    )
    string = '<>_not underlined_</>'
    assert_equal(
      string,
      @o.markup_underline( string ),
    )
    string = <<-heredoc.unindent
        _not
        underlined_
      heredoc
    assert_equal(
      string,
      @o.markup_underline( string ),
    )
    string = <<-heredoc.unindent
        <>
        _not underlined_
        </>
      heredoc
    assert_equal(
      string,
      @o.markup_underline( string ),
    )
    string = '<>_not underlined_</><>_not underlined_</>'
    assert_equal(
      string,
      @o.markup_underline( string ),
    )
    string = <<-heredoc.unindent
      <>
      _not underlined_
      </>
      <>
      _not underlined_
      </>
    heredoc
    assert_equal(
      string,
      @o.markup_underline( string ),
    )
    #string = <<-heredoc.unindent
      #<>
      #<>
      #_not underlined_
      #</>
      #_not underlined_
      #</>
    #heredoc
    #assert_equal(
      #string,
      #@o.markup_underline( string ),
    #)
  end

  def xx_test_markup_strong()
    assert_equal(
      '<strong>strong</strong>',
      @o.markup_strong( '*strong*' ),
    )
  end

  def xx_test_markup_emphasis()
    assert_equal(
      '<em>emphasis</em>',
      @o.markup_emphasis( '/emphasis/' ),
    )

    assert_equal(
      '<html>/no</html><em>emphasis</em>',
      @o.markup_emphasis( '<html>/no</html>/emphasis/' ),
    )

    assert_equal(
      '<em>usr/bin</em>',
      @o.markup_emphasis( '/usr/bin/' ),
    )

    # Markup does not cross HTML bounderies.
    # Because that would be insanity.
    string = '<em>emp<html>/no</html>hasis</em>'
    assert_equal(
      string,
      @o.markup_emphasis( string ),
    )
  end

  def xx_test_multiple_everything()
    assert_equal(
      '<u>underlined</u> and <strong>strong</strong>',
      @o.markup_everything( '_underlined_ and *strong*' ),
    )
  end

  def xx_test_nested_markup()
    # This demonstrates how the first markup's html-result will stop any future markup from acting within that html.
    assert_equal(
      '<u>*underlined*</u> <strong>strong</strong>',
      @o.markup_everything( @o.markup_underline( '_*underlined*_ *strong*' ) ),
    )
  end

  def xx_test_big()
    assert_equal(
      '<big>big</big>',
      @o.markup_big( @o.markup_underline( '**big**' ) ),
    )
    # This demonstrates the need for markup done in a specific order.  Big has to be performed before bold.
    assert_equal(
      '<big>big</big>',
      @o.markup_everything( @o.markup_underline( '**big**' ) ),
    )
  end

  def xx_test_sections_arrays_multiple()
    string = <<-heredoc.unindent
      This is an example document.
      
      = Title One =
      
      Text in section one.
      
      = Title Two =
      
      Text in section two.
    heredoc
    nomatch, match = @o.sections_arrays( string )
    assert_equal(
      [ "This is an example document.\n\n", nil, '', "\n\nText in section one.\n\n", nil, "\n\nText in section two.\n" ],
      nomatch,
    )
    assert_equal(
      [ nil, '= Title One =', nil, nil, '= Title Two =', nil],
      match,
    )
  end

  def xx_test_sections()
    expected = <<-heredoc.unindent
      <div class="s1"><h1>1</h1>
      </div>
    heredoc
    match, nomatch = @o.sections( <<-heredoc.unindent
      = 1 =
    heredoc
    )
    result = @o.recombine( match, nomatch ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )
  end

  def xx_test_sections_large()
    expected = <<-heredoc.unindent
      <div class="s1"><div class="s2"><div class="s3"><h3>3</h3>
      </div></div></div>
    heredoc
    match, nomatch = @o.sections( <<-heredoc.unindent
      === 3 ===
    heredoc
    )
    result = @o.recombine( match, nomatch ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )
  end

  def xx_test_sections_multiple()
    expected = <<-heredoc.unindent
      <div class="s1"><h1>1</h1>
  
      </div><div class="s1"><h1>2</h1>
      </div>
    heredoc
    match, nomatch = @o.sections( <<-heredoc.unindent
      = 1 =
      = 2 =
    heredoc
    )
    result = @o.recombine( match, nomatch ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )
  end

  def xx_test_sections_increment()
    expected = <<-heredoc.unindent
      <div class="s1"><h1>1</h1>
  
      <div class="s2"><h2>2</h2>
      </div></div>
    heredoc
    match, nomatch = @o.sections( <<-heredoc.unindent
      = 1 =
      == 2 ==
    heredoc
    )
    result = @o.recombine( match, nomatch ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )
  end

  def xx_test_sections_increment_lots()
    expected = <<-heredoc.unindent
      <div class="s1"><h1>1</h1>

      <div class="s2"><div class="s3"><h3>3</h3>
      </div></div></div>
    heredoc
    match, nomatch = @o.sections( <<-heredoc.unindent
      = 1 =
      === 3 ===
    heredoc
    )
    result = @o.recombine( match, nomatch ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )
  end

  def xx_test_sections_increment2()
    expected = <<-heredoc.unindent
      <div class="s1"><div class="s2"><h2>2</h2>
  
      <div class="s3"><div class="s4"><h4>4</h4>
      </div></div></div></div>
    heredoc
    match, nomatch = @o.sections( <<-heredoc.unindent
      == 2 ==
      ==== 4 =====
    heredoc
    )
    result = @o.recombine( match, nomatch ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )
  end

  def xx_test_sections_decrement()
    expected = <<-heredoc.unindent
      <div class="s1"><div class="s2"><h2>2</h2>

      </div></div><div class="s1"><h1>1</h1>
      </div>
    heredoc
    match, nomatch = @o.sections( <<-heredoc.unindent
      == 2 ==
      = 1 =
    heredoc
    )
    result = @o.recombine( match, nomatch ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )
  end

  def xx_test_sections_decrement_lots()
    expected = <<-heredoc.unindent
      <div class="s1"><div class="s2"><div class="s3"><h3>3</h3>

      </div></div></div><div class="s1"><h1>1</h1>
      </div>
    heredoc
    match, nomatch = @o.sections( <<-heredoc.unindent
      === 3 ===
      = 1 =
    heredoc
    )
    result = @o.recombine( match, nomatch ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )
  end

  def xx_test_paragraphs()
    assert_equal(
      "<p>foo</p>",
      @o.paragraphs( 'foo' ),
    )
    assert_equal(
      "<p>one</p>\n<p>two</p>",
      @o.paragraphs( "one\n\ntwo" ),
    )
    assert_equal(
      "<p>one</p>\n<br />\n<p>two</p>",
      @o.paragraphs( "one\n\n\ntwo" ),
    )
  end

  def xx_test_HTML_horizontal_rules()
    assert_equal(
      ( <<-heredoc.unindent
        line one
      heredoc
      ),
      @o.HTML_horizontal_rules( <<-heredoc.unindent
        line one
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        line one
        
        <hr>
        
        line two
      heredoc
      ),
      @o.HTML_horizontal_rules( <<-heredoc.unindent
        line one
        
        ---
        
        line two
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        line one
        <hr class="small">
        line two
      heredoc
      ),
      @o.HTML_horizontal_rules( <<-heredoc.unindent
        line one
        ---
        line two
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        Test >
        <hr class="small">
        
        content
      heredoc
      ),
      @o.HTML_horizontal_rules( <<-heredoc.unindent
        Test >
        ---
        
        content
      heredoc
      ),
    )

  end

  def xx_test_links_plain()
    assert_equal(
      ( <<-heredoc.unindent
        foo
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        foo
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com">example.com</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://example.com
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        before <a href="http://example.com">example.com</a> after
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        before http://example.com after
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com/">example.com/</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://example.com/
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com/foo">example.com/foo</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://example.com/foo
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com/foo/">example.com/foo/</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://example.com/foo/
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://127.0.0.1">127.0.0.1</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://127.0.0.1
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://127.0.0.1/">127.0.0.1/</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://127.0.0.1/
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://127.0.0.1/foo">127.0.0.1/foo</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://127.0.0.1/foo
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://127.0.0.1/foo/">127.0.0.1/foo/</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://127.0.0.1/foo/
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com:1234">example.com:1234</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://example.com:1234
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com:1234/">example.com:1234/</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://example.com:1234/
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com:1234/foo">example.com:1234/foo</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://example.com:1234/foo
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com:1234/foo/">example.com:1234/foo/</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        http://example.com:1234/foo/
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        line one
        <a href="http://example.com/foo/index.php?bar|baz#quux">example.com/foo/index.php?bar|baz#quux</a>
        line two
        <a href="http://example.com:1234/foo/">example.com:1234/foo/</a>
      heredoc
      ),
      @o.links_plain( <<-heredoc.unindent
        line one
        http://example.com/foo/index.php?bar|baz#quux
        line two
        http://example.com:1234/foo/
      heredoc
      ),
    )


  end

  def xx_test_links_named()
    assert_equal(
      ( <<-heredoc.unindent
        foo
      heredoc
      ),
      @o.links_named( <<-heredoc.unindent
        foo
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com">foo</a>
      heredoc
      ),
      @o.links_named( <<-heredoc.unindent
        [http://example.com foo]
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com">two words</a>
      heredoc
      ),
      @o.links_named( <<-heredoc.unindent
        [http://example.com two words]
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        before <a href="http://example.com">two words</a> after
      heredoc
      ),
      @o.links_named( <<-heredoc.unindent
        before [http://example.com two words] after
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        line one
        before <a href="http://example.com/foo/index.php?bar|baz#quux">foo bar</a> after
        line two
        before <a href="http://example.com">two words</a> after
      heredoc
      ),
      @o.links_named( <<-heredoc.unindent
        line one
        before [http://example.com/foo/index.php?bar|baz#quux foo bar] after
        line two
        before [http://example.com two words] after
      heredoc
      ),
    )
  end

  def xx_test_links_numbered()
    assert_equal(
      ( <<-heredoc.unindent
        foo
      heredoc
      ),
      @o.links_numbered( (<<-heredoc.unindent
        foo
      heredoc
      ),
      '',
      '',
      '',
      '',
      1
      )[0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com">1</a>
      heredoc
      ),
      @o.links_numbered( (<<-heredoc.unindent
        [http://example.com]
      heredoc
      ),
      '',
      '',
      '',
      '',
      0
      )[0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        before <a href="http://example.com">1</a> after
      heredoc
      ),
      @o.links_numbered( (<<-heredoc.unindent
        before [http://example.com] after
      heredoc
      ),
      '',
      '',
      '',
      '',
      0
      )[0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="http://example.com">[1]</a>
      heredoc
      ),
      @o.links_numbered( (<<-heredoc.unindent
        [http://example.com]
      heredoc
      ),
      '',
      '',
      '[',
      ']',
      0
      )[0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        [<a href="http://example.com">1</a>]
      heredoc
      ),
      @o.links_numbered( (<<-heredoc.unindent
        [http://example.com]
      heredoc
      ),
      '[',
      ']',
      '',
      '',
      0
      )[0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        [<a href="http://example.com">a1b</a>]
        [<a href="http://exampletwo.com">a2b</a>]
      heredoc
      ),
      @o.links_numbered( (<<-heredoc.unindent
        [http://example.com]
        [http://exampletwo.com]
      heredoc
      ),
      '[',
      ']',
      'a',
      'b',
      0
      )[0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        [<a href="http://example.com">a1b</a>]
        a [<a href="http://exampletwo.com">a2b</a>] b
      heredoc
      ),
      @o.links_numbered( (<<-heredoc.unindent
        [http://example.com]
        a [http://exampletwo.com] b
      heredoc
      ),
      '[',
      ']',
      'a',
      'b',
      0
      )[0],
    )

    # Don't link this sort of thing.  Someone's being retarded and is mixing in the syntax for a new link.
    assert_equal(
      ( <<-heredoc.unindent
        [[http://example.com]]
      heredoc
      ),
      @o.links_numbered( (<<-heredoc.unindent
        [[http://example.com]]
      heredoc
      ),
      '',
      '',
      '[',
      ']',
      0
      )[0],
    )
  end

  # Naughty tests touch the disk.
  def xx_test_links_automatic()
    verbose_old = $VERBOSE
    $VERBOSE = false
    create_file( '/tmp/foo.asc', '' )
    create_file( '/tmp/bar.asc', '' )
    create_file( '/tmp/foo-bar.asc', '' )
    create_file( '/tmp/compiled-website-test-file.asc', '' )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="foo.html">foo</a>
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        foo
      heredoc
      ),
        '/tmp/something.asc'
      )
    )

    # Only link the first word.
    assert_equal(
      ( <<-heredoc.unindent
        <a href="foo.html">foo</a> foo
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        foo foo
      heredoc
      ),
        '/tmp/something.asc'
      )
    )

    # Only link the first word.  No, seriously.
    assert_equal(
      ( <<-heredoc.unindent
        <a href="foo.html">foo</a> <a href="a">a</a> foo
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        foo <a href="a">a</a> foo
      heredoc
      ),
        '/tmp/something.asc'
      )
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="bar.html">bar</a>
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        bar
      heredoc
      ),
        '/tmp/something.asc'
      )
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="foo-bar.html">foo bar</a>
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        foo bar
      heredoc
      ),
        '/tmp/something.asc'
      )
    )

    assert_equal(
      ( <<-heredoc.unindent
        <a href="compiled-website-test-file.html">compiled website test file</a>
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        compiled website test file
      heredoc
      ),
        '/tmp/something.asc'
      )
    )

    # Working with single words then removing them as possibilities.
    assert_equal(
      ( <<-heredoc.unindent
        <a href="foo.html">foo</a>
        <a href="bar.html">bar</a> <a href="foo-bar.html">foo bar</a>
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        foo
        bar foo bar
      heredoc
      ),
        '/tmp/something.asc'
      )
    )

    # Case-insensitive matches.
    assert_equal(
      ( <<-heredoc.unindent
        <a href="foo.html">Foo</a>
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        Foo
      heredoc
      ),
        '/tmp/something.asc'
      )
    )

    # Allow matching within punctuation and specific endings
    assert_equal(
      ( <<-heredoc.unindent
        <a href="foo.html">foo</a>ed
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        fooed
      heredoc
      ),
        '/tmp/something.asc'
      )
    )

    # Match, ignoring dashes in the source text.
    assert_equal(
      ( <<-heredoc.unindent
        <a href="compiled-website-test-file.html">compiled-website test file</a>
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        compiled-website test file
      heredoc
      ),
        '/tmp/something.asc'
      )
    )

    # Don't match the current document's name.
    assert_equal(
      ( <<-heredoc.unindent
        foo
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        foo
      heredoc
      ),
        '/tmp/foo.asc'
      )
    )

    # FIXME:  This broke after I made the change to use html_arrays() everywhere.
    ## Prioritizing two words before single words.
    #assert_equal(
      #( <<-heredoc.unindent
        #<a href="foo-bar.html">foo bar</a> <a href="foo.html">foo</a> <a href="bar.html">bar</a>
      #heredoc
      #),
      #@o.links_automatic( (<<-heredoc.unindent
        #foo bar foo bar
      #heredoc
      #),
        #'/tmp/something.asc'
      #)
    #)

 if $slow == true then
    # Do not allow matching within words.  Require punctuation.
    # FIXME:  There's a serious speed issue here.  =(
    assert_equal(
      ( <<-heredoc.unindent
        abcfoodef
      heredoc
      ),
      @o.links_automatic( (<<-heredoc.unindent
        abcfoodef
      heredoc
      ),
        '/tmp/something.asc'
      )
    )
end

    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/bar.asc' )
    File.delete( '/tmp/foo-bar.asc' )
    File.delete( '/tmp/compiled-website-test-file.asc' )

    $VERBOSE = verbose_old
  end

  # Naughty tests touch the disk.
  def xx_test_links_local_new()
    verbose_old = $VERBOSE
    $VERBOSE = false
    if File.exists?( '/tmp/foo.asc' ) then
      File.delete( '/tmp/foo.asc' )
    end
    if File.exists?( '/tmp/bar.asc' ) then
      File.delete( '/tmp/bar.asc' )
    end
    if File.exists?( '/tmp/baz.asc' ) then
      File.delete( '/tmp/baz.asc' )
    end

    create_file( '/tmp/foo.asc', '[[bar]]' )
    # Standard usage.  Create a new empty file and link to it.
    assert_equal(
      '<a class="new" href="file:///tmp/bar.asc">bar</a>',
      @o.links_local_new( 
        file_read( '/tmp/foo.asc' ),
        '/tmp/foo.asc',
      ),
    )
    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/bar.asc' )

    create_file( '/tmp/foo.asc', 'before [[bar]] after' )
    # Standard usage.  Create a new empty file and link to it.
    assert_equal(
      'before <a class="new" href="file:///tmp/bar.asc">bar</a> after',
      @o.links_local_new( 
        file_read( '/tmp/foo.asc' ),
        '/tmp/foo.asc',
      ),
    )
    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/bar.asc' )
    
    # Second usage.  Remove [[ ]] for non-empty and already-existing files, to allow links_automatic() to operate.
    create_file( '/tmp/foo.asc', '[[bar]]' )
    # An empty file is referenced.  Therefore keep [[ ]]
    create_file( '/tmp/bar.asc', '' )
    assert_equal(
      '<a class="new" href="file:///tmp/bar.asc">bar</a>',
      @o.links_local_new( 
        file_read( '/tmp/foo.asc' ),
        '/tmp/foo.asc',
      ),
    )
    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/bar.asc' )

    # Second usage.  Remove [[ ]] for non-empty and already-existing files, to allow links_automatic() to operate.
    create_file( '/tmp/foo.asc', '[[bar]]' )
    # A non-empty file is referenced.  Therefore remove [[ ]]
    create_file( '/tmp/bar.asc', 'non-empty' )
    assert_equal(
      'bar',
      @o.links_local_new( 
        file_read( '/tmp/foo.asc' ),
        '/tmp/foo.asc',
      ),
    )
    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/bar.asc' )

    # Testing two-word references.
    create_file( '/tmp/foo.asc', '[[bar baz]]' )
    assert_equal(
      '<a class="new" href="file:///tmp/bar-baz.asc">bar baz</a>',
      @o.links_local_new( 
        file_read( '/tmp/foo.asc' ),
        '/tmp/foo.asc',
      ),
    )
    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/bar-baz.asc' )

    # Testing creating two new files.
    create_file( '/tmp/foo.asc', '[[bar]] [[baz]]' )
    assert_equal(
      '<a class="new" href="file:///tmp/bar.asc">bar</a> <a class="new" href="file:///tmp/baz.asc">baz</a>',
      @o.links_local_new( 
        file_read( '/tmp/foo.asc' ),
        '/tmp/foo.asc',
      ),
    )
    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/bar.asc' )
    File.delete( '/tmp/baz.asc' )

    $VERBOSE = verbose_old
  end

  # Naughty tests touch the disk.
  def xx_test_links_mixed()
    verbose_old = $VERBOSE
    $VERBOSE = false
  
    # automatic and new.
    if File.exists?( '/tmp/foo.asc' ) then
      File.delete( '/tmp/foo.asc' )
    end
    if File.exists?( '/tmp/bar.asc' ) then
      File.delete( '/tmp/bar.asc' )
    end
    if File.exists?( '/tmp/baz.asc' ) then
      File.delete( '/tmp/baz.asc' )
    end
    if File.exists?( '/tmp/quux.asc' ) then
      File.delete( '/tmp/quux.asc' )
    end

    # Testing creating two new files.
    create_file( '/tmp/foo.asc', '[[bar]] [[baz]] [[quux]]' )
    create_file( '/tmp/baz.asc', 'non-empty' )
    filename = '/tmp/foo.asc'

    # [[baz]] already exists and is non-empty.  It should be auto-linked.
    # FIXME
    #assert_equal(
      #'<a class="new" href="file:///tmp/bar.asc">bar</a> <a href="baz.html">baz</a> <a class="new" href="file:///tmp/quux.asc">quux</a>',
      #@o.links_automatic(
        #@o.links_local_new( 
          #file_read( filename ),
          #filename,
        #),
        #filename,
      #),
    #)
    #File.delete( '/tmp/bar.asc' )
    #File.delete( '/tmp/quux.asc' )

    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/baz.asc' )

    $VERBOSE = verbose_old
  end

  def xx_test_lists_arrays()
    assert_equal(
      ( <<-heredoc.unindent
        foo
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        foo
      heredoc
      )[0][0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        - foo
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        - foo
      heredoc
      )[1][0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        # foo
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        # foo
      heredoc
      )[1][0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        before
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        before
        - foo
      heredoc
      )[0][0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        after
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        before
        - foo
        after
      heredoc
      )[0][2],
    )

    assert_equal(
      ( <<-heredoc.unindent
        - foo
        - bar
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        - foo
        - bar
      heredoc
      )[1][0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        - foo
        # bar
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        - foo
        # bar
      heredoc
      )[1][0],
    )

    # Single blank lines are allowed, but removed.
    assert_equal(
      ( <<-heredoc.unindent
        - foo
        - bar
        - baz
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        - foo
        
        - bar
        - baz
      heredoc
      )[1][0],
    )

    # Indentation is allowed, but removed.
    assert_equal(
      ( <<-heredoc.unindent
        - foo
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc
        - foo
      heredoc
      )[1][0],
    )

    # Indentation is allowed, but removed.
    assert_equal(
      ( <<-heredoc.unindent
        - foo
        - bar
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc
        - foo
        - bar
      heredoc
      )[1][0],
    )

    # Indentation is allowed, but removed.
    assert_equal(
      ( <<-heredoc.unindent
        - foo
        - bar
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc
        - foo
        
        - bar
      heredoc
      )[1][0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        - foo
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        - foo
        
        
        - bar
      heredoc
      )[1][0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        - bar
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        - foo
        
        
        - bar
      heredoc
      )[1][3],
    )

    assert_equal(
      ( <<-heredoc.unindent
        - one
        - two
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        - one
        - two
        
        
        - three
      heredoc
      )[1][0],
    )

    assert_equal(
      ( <<-heredoc.unindent
        - three
      heredoc
      ).chomp,
      @o.lists_arrays( <<-heredoc.unindent
        - one
        - two
        
        
        - three
      heredoc
      )[1][3],
    )

  end

  def xx_test_lists()

    assert_equal(
      ( <<-heredoc.unindent
        foo
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        foo
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one</li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        - one
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <ol>
        <li>one</li>
        </ol>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        # one
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        before
        <ul>
        <li>one</li>
        </ul>
        after
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        before
        - one
        after
      heredoc
      ),
    )

    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one</li>
        <li>two</li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        - one
        - two
      heredoc
      ),
    )

    # Single blank lines are combined.
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one</li>
        <li>two</li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        - one
        
        - two
      heredoc
      ),
    )

    # Allow indentation
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one</li>
        <li>two</li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc
        - one
        - two
      heredoc
      ),
    )

    # Allow indentation /and/ spaces.  Lists separated by single blank lines are combined.
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one</li>
        <li>two</li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc
        - one
        
        - two
      heredoc
      ),
    )

    # Allow indentation.  Lists separated by two blank lines are separate lists.
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one</li>
        </ul>
        
        
        <ul>
        <li>two</li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        - one
        
        
        - two
      heredoc
      ),
    )

    # Nested lists.
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one
        <ul>
        <li>two</li>
        </ul>
        </li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        - one
        -- two
      heredoc
      ),
    )

    # Nested lists, changing type
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one
        <ol>
        <li>two</li>
        </ol>
        </li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        - one
        ## two
      heredoc
      ),
    )

    # Initial list is nested
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>
        <ul>
        <li>one</li>
        </ul>
        </li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        -- one
      heredoc
      ),
    )

    # Initial list is nested
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>
        <ul>
        <li>
        <ul>
        <li>one</li>
        </ul>
        </li>
        </ul>
        </li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        --- one
      heredoc
      ),
    )

    # Nested lists, incrementing then decrementing
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one
        <ul>
        <li>two</li>
        </ul>
        </li>
        <li>three</li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        - one
        -- two
        - three
      heredoc
      ),
    )

    # Nesting lists, incrementing a lot.
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one
        <ul>
        <li>
        <ul>
        <li>two</li>
        </ul>
        </li>
        </ul>
        </li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        - one
        --- two
      heredoc
      ),
    )

    # Nesting lists, incrementing a lot.
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one
        <ul>
        <li>
        <ul>
        <li>
        <ul>
        <li>two</li>
        </ul>
        </li>
        </ul>
        </li>
        </ul>
        </li>
        </ul>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        - one
        ---- two
      heredoc
      ),
    )

# TODO -- testing past here.
    ## Nesting lists, incrementing a lot, then decrementing a lot.
    #assert_equal(
      #( <<-heredoc.unindent
        #<ul>
        #<li>one
        #<ul>
        #<li>
        #<ul>
        #<li>two</li>
        #</ul>
        #</li>
        #</ul>
        #</li>
        #<li>three</li>
        #</ul>
      #heredoc
      #).chomp,
      #@o.lists( <<-heredoc.unindent
        #- one
        #--- two
        #- three
      #heredoc
      #),
    #)

    ## Mixed lists
    #assert_equal(
      #( <<-heredoc.unindent
        #<ul>
        #<li>one</li>
        #</ul>
        #<ol>
        #<li>two</li>
        #</ol>
      #heredoc
      #).chomp,
      #@o.lists( <<-heredoc.unindent
        #- foo
        ## bar
      #heredoc
      #),
    #)

# TODO:  Mixed lists, incrementing a lot.
# TODO:  Mixed lists, incrementing then decrementing a lot.

    ## And now let's try to break the damned thing!
    #assert_equal(
      #( <<-heredoc.unindent
        #<ul>
        #<li>
        #<ul>
        #<li>one</li>
        #</ul>
        #</li>
        #</ul>
        #<ol>
        #<li>
        #<ol>
        #<li>two</li>
        #</ol>
        #</li>
        #</ol>
        #<ul>
        #<li>three
        #<ul>
        #<li>four
        #<ul>
        #<li>five</li>
        #</ul>
        #</li>
        #</ul>
        #</li>
        #</ul>
        #<ol>
        #<li>oh
        #<ol>
        #<li>
        #<ol>
        #<li>here</li>
        #</ol>
        #</li>
        #</ol>
        #</li>
        #</ol>
      #heredoc
      #).chomp,
      #@o.lists( <<-heredoc.unindent
      #-- one
      ### two
      #- three
      #-- four
      #--- five
      #-----
      ## oh
      #### here
      #heredoc
      #),
    #)

  end

  def xx_test_blocks_arrays()

    #assert_equal(
      #( <<-heredoc
        #foo
      #heredoc
      #),
      #@o.blocks_arrays( <<-heredoc
        #foo
      #heredoc
      #)[0][0],
    #)

    #assert_equal(
      #nil,
      #@o.blocks_arrays( <<-heredoc
        #foo
      #heredoc
      #)[1][0],
    #)

    # Interspersed with text.
    assert_equal(
      ( "  one\n  two\n" ),
      @o.blocks_arrays( <<-heredoc.unindent
        before
          one
          two
        after
      heredoc
      )[1][1],
    )


    # Interspersed with text.
    assert_equal(
      ( "  three\n  four\n" ),
      @o.blocks_arrays( <<-heredoc.unindent
        before
          one
          two
        after
        
          three
          four
      heredoc
      )[1][3],
    )

    assert_equal(
      ( <<-heredoc.unindent
        before
        should be captured
      heredoc
      ),
      @o.blocks_arrays( <<-heredoc.unindent
        before
        should be captured
          one
          two
        
        after
        also this
      heredoc
      )[0][0],
    )

    assert_equal(
      ( "\n" + <<-heredoc.unindent
        after
        also this
      heredoc
      ),
      @o.blocks_arrays( <<-heredoc.unindent
        before
        should be captured
          one
          two
        
        after
        also this
      heredoc
      )[0][2],
    )

  end
  
  def xx_test_blocks()
  
    assert_equal( 
      ( <<-heredoc.unindent
        foo
      heredoc
      ),
      @o.blocks( <<-heredoc.unindent
        foo
      heredoc
      ),
    )

    assert_equal( 
      ( <<-heredoc.unindent
        before
        <pre>
        some text
        </pre>
      heredoc
      ),
      @o.blocks( <<-heredoc.unindent
        before
          some text
      heredoc
      ),
    )
  
    assert_equal( 
      ( <<-heredoc.unindent
        before
        <pre>
        some text
        </pre>
        after
      heredoc
      ),
      @o.blocks( <<-heredoc.unindent
        before
          some text
        after
      heredoc
      ),
    )
  
    assert_equal( 
      ( <<-heredoc.unindent
        before
        <pre>
        some text
          indented text
        </pre>
        after
      heredoc
      ),
      @o.blocks( <<-heredoc.unindent
        before
          some text
            indented text
        after
      heredoc
      ),
    )
  
  end

end

# The below code was mostly copied from the previous generation of this codebase.
# ---


def create_file( file, file_contents )
  # TODO: This can't create a file if it's in a subdirectory that doesn't exist.  I get a TypeError.  Perhaps I could intelligently create the directory..
  vputs "creating file: " + file
  # TODO: check that I have write access to my current directory.
  # TODO: check for overwriting an existing file.  Also implement an optional flag to overwrite it.
  begin
    File.open( file, 'w+' ) { |f| # open file for update
      f.print file_contents       # write out the example description
    }                             # file is automatically closed
  rescue Exception
    # TODO:  Causes issues, but I'm not sure why.
#    raise "\nCreating the text file #{file.inspect} has failed with: "
  end
end

def vputs( string )
  if $VERBOSE == true || $VERBOSE == nil then
    puts string
  end
end

def cd_directory( directory )
  # TODO:  I have not done proper testing on any of this.  I don't even know if "raise" works.
  # This is the equivalent of:  directory=exec("readlink", "-f", Dir.getwd)
  directory=File.expand_path(directory)
  start_directory = Dir.getwd

  # TODO: Check permissions
  if directory == start_directory then
    vputs "cd_directory: I'm already in that directory:  " + directory.inspect
    return 0
  end
  if not File.directory?(directory) then
    raise "cd_directory: That's not a directory:  " + directory.inspect
    return 1
  end
  if not File.exists?(directory) then
    raise "cd_directory: That directory doesn't exist:  " + directory.inspect
    return 1
  end

  vputs "cd_directory: entering directory: " + directory.inspect
  Dir.chdir( directory )
  # This is a good idea, but it fails if I'm in a symlinked directory..
  # TODO: Recursively check if I'm in a symlinked dir.  =)
#   if Dir.getwd != directory then
#     puts "cd failed.  I'm in\n" + Dir.getwd + "\n.. but you wanted \n" + directory
#     return 1
#   end
end

# TODO:  Automatically make parent directories if they don't exist, like `md --parents`.
def md_directory( directory )
  directory=File.expand_path(directory)
  if File.exists?(directory) then
    if File.directory?(directory) then
      # All is good!
      return 0
    else
      raise "md_directory: It's a file, I can't make a directory of the same name!:  " + directory.inspect
      return 1
    end
  end
  # TODO:  Suppress explosions using Signal.trap, and deal with things gracefully.
  #        e.g.  Signal.trap("HUP") { method() }
  #        Apply this technique elsewhere/everywhere.
  vputs "md_directory: making directory: " + directory.inspect

  # This can make parent directories
  FileUtils.mkdir_p( directory )
  # This cannot make parent directories.  I could program a workaround so I don't need to require 'fileutils', but why?
  # Dir.mkdir( directory )

  # Fails if I'm in a symlinked directory.  See notes with cd_directory.
#   if File.directory?(directory) == false then raise "directory creation failed: " + directory end
  # TODO: ensure that I have complete access (read/write, make directories)
  # TODO: Attempt to correct the permissions.
end

def pid_exists?( pid )
  begin
    Process.kill( 0, pid )
    # exists
    return 0
  rescue Errno::EPERM
    # changed uid
    return 128
  rescue Errno::ESRCH
    # does not exist or zombied
    # TODO: zombied?  That could be really bad.  I would want to kill-9 those, but I can't tell the difference between nonexistant and zombied.. argh argh argh!
    return 1
  rescue
    # Could not check the status?  See  $!
    return 255
  end
end

def fork_killer( pid_file )
  # TODO: Allow a method before the loop and after the loop (in seppuku).  This prevents unnecessarily repeating code.  However, it introduces the issue of how I ought to pass variables around.  It's not worth the work right now, but it's a big issue to solve later.
  Dir[pid_file + '**'].each do |file|
    pid = File.extname( file )[1..-1].to_i
    # If the process exists:
    if pid_exists?( pid ) == 0 then
      # Ask it to terminate.
      begin
        Process.kill( "HUP", pid )
      rescue Errno::ESRCH
        vputs "**explosion!**"
      end
      # The exiting process will kill its own pid file.
    else
      vputs file + " doesn't actually have a running process.  Deleting it."
      File.delete( file )
    end
  end
end

def fork_helper( *args, &block )
  pid_file = args[0]
  pid = fork do
    pidfile = pid_file + "." + $$.to_s
    create_file( pidfile, $$ )
    def fork_helper_seppuku( pid_file )
        vputs "pid #{$$} was killed."
        # TODO: Appropriately-kill any other forked processes, and delete their pid files.
        # 1.9.2 introduced an oddity where after a time this would get triggered twice.
        # Checking for existence is a cludgy workaround.
        if File.exists?( pid_file + "." + $$.to_s ) then
          File.delete(   pid_file + "." + $$.to_s )
        end
        exit
    end
    Signal.trap( "HUP"  ) { fork_helper_seppuku( pid_file ) }
    Signal.trap( "TERM" ) { fork_helper_seppuku( pid_file ) }
    vputs "started #{$$}"
#    until "sky" == "falling" do
    loop do
#       vputs "pid #{$$} sleeping"
      yield
#       vputs "\n\n\n\n\n\n\n"
      sleep 1
    end
  end
end
def test_fork
  pid_file = File.join( '', 'tmp' 'test_fork_pid' )

  fork_killer( pid_file )
  fork_helper( pid_file ) {
    puts "process #{$$} is working:  #{Time.now}"
  }
end
#test_fork()
# Once your done testing, comment out test_fork and uncomment this.  It'll kill the one remaining fork.
# fork_killer( File.join( '', 'tmp', 'test_fork_pid' ) )

def file_read( file )
  vputs "Reading file " + file
  # I suspect that there are issues reading files with a space in them.  I'm having a hard time tracking it down though.. TODO: I should adjust the test case.
  if ! File.exists?( file ) then
    puts "That file doesn't exist: "  + file.inspect
    return ""
  end
  # TODO: Check permissions, etc.
# file=file.sub(' ', '_')
  f = File.open( file, 'r' )
    string = f.read
  f.close
  return string
end
def test_file_read()
  lib = "~/bin/rb/lib/"
  # FIXME:  This shouldn't be requiring other stuff, that'd be bad testing!
  require lib + "mine/misc.rb"
  require lib + "mine/files.rb"
  working_file = "/tmp/test_file_read.#{$$}"
  create_file( working_file, "This is some content!" )
  puts file_read( working_file )
  File.delete( working_file )
end


# ---

def timestamp_sync( source_file, target_file, &block )
  # TODO:  Sanity-checking.
  if ! File.exists?( source_file ) || ! File.exists?( target_file ) then return 1 end
  stime = File.stat( source_file ).mtime
  ttime = File.stat( target_file ).mtime
  if stime != ttime then
#     puts "this should be displayed ONCE"
    vputs " # The source and target times are different.  Fixing the target time."
    vputs "   Source: #{source_file} to #{stime}"
    vputs "   Target: #{target_file} to #{ttime}"
    File.utime( stime, stime, target_file )
    if File.stat( target_file ).mtime != stime then
      puts "Failed to set the time!"
      return 1
    end
    yield if block_given?
    return true
  else
    return false
  end
end
def test_timestamp_sync()
  # Setup
  lib = File.join('', 'home', 'user', 'bin', 'rb', 'lib')
  require File.join(lib, "mine", "misc.rb")
  require File.join(lib, "mine", "strings.rb")
  require File.join(lib, "mine", "directories.rb")
  require File.join(lib, "mine", "files.rb")
  # $$ is the pid of the current process.  That should make this safer.
  working_dir=File.join('', 'tmp', "test_timestamp_sync.#{$$}")
  source_file=File.join(working_dir, "source")
  target_file=File.join(working_dir, "target")
  # Preparing directories
  md_directory(working_dir)
  # Preparing files
  create_file(source_file, "content")
  # Sleep, to force the timestamp to be wrong
  sleep 1.5
  create_file(target_file, "content")
  # NOTE: The following code is not portable!
  system("\ls", "-lG", "--time-style=full-iso", working_dir)

  # Test
  puts " # First pass."
  timestamp_sync(source_file, target_file)
  puts " # Second pass."
  timestamp_sync(source_file, target_file)
  puts " # There should be no output."
  # Teardown
  # FIXME: Trap all errors and then perform my cleanup.  Fix all my test scripts to do this.
  # NOTE: The following code is not portable!
  system("\ls", "-lG", "--time-style=full-iso", working_dir)
  rm_directory( working_dir )
end # test_timestamp_sync

def generate_sitemap( target_file_full_path, local_dir, source_file_full_path, type )
  return 0
end


def main( local_wiki, local_blog, remote_wiki, remote_blog, pid_file )
  def process( local_dir, source_file_full_path, target_file_full_path, type )
    compile(        source_file_full_path, target_file_full_path, type )
    timestamp_sync( source_file_full_path, target_file_full_path )
    # TODO/FIXME: Re-compile all files in that same source directory, to ensure that automatic linking is re-applied to include this new file
  end

  def check_for_source_changes( local_dir, remote_dir, type )
=begin
    case type
      when 'wiki' then
      when 'blog' then
        # I haven't figured this out yet.
        return nil
#        local_dir  = File.join( local_dir,   '..', 'blog' )
#        remote_dir = File.join( remote_dir,        'blog' )
      else
        puts 'eek!'
        return nil
    end
=end

    if Dir.getwd != File.expand_path( local_dir ) then
      # Yes, this keeps switching directories between the wiki and blog.  I don't need vputs to constantly tell me this.
      oldverbose = $VERBOSE
      $VERBOSE = false
      cd_directory( local_dir )
      $VERBOSE = oldverbose
    end
    # This was '**/*.asc' but I'm not going to look into subdirectories any more.
    Dir['*.asc'].each do |asc_file|
      target_file_full_path = File.expand_path( File.join( remote_dir, asc_file.chomp( '.asc' ) + '.html' ) )
      source_file_full_path = File.expand_path(asc_file)
      # Skip empty files.
      next if not File.size?( source_file_full_path )
      if not File.exists?( target_file_full_path )  then
        vputs ''
        vputs 'Building missing file:  ' + source_file_full_path.inspect
        vputs ' ...             into:  ' + target_file_full_path.inspect
        process( local_dir, source_file_full_path, target_file_full_path, type )
        generate_sitemap( File.dirname( target_file_full_path ), local_dir, source_file_full_path, type )
        next
      end
      source_time=File.stat( source_file_full_path ).mtime
      target_time=File.stat( target_file_full_path ).mtime
      if not source_time == target_time then
        target_path=File.join( remote_dir, File.dirname( asc_file ) )
        vputs ''
        vputs 'Building unsynced timestamps:  ' + source_file_full_path.inspect
        vputs ' ...                    with:  ' + target_file_full_path.inspect
        process( local_dir, source_file_full_path, target_file_full_path, type )
        next
      end
    end # Dir['*.asc'].each do |asc_file|
  end # check_for_source_changes( local_dir, remote_dir, type )


  # Kill any existing process.
  fork_killer( pid_file )

  # The main loop - once a second.
  fork_helper( pid_file ) do
    check_for_source_changes( local_wiki, remote_wiki, 'wiki' )
    check_for_source_changes( local_blog, remote_blog, 'blog' )
#    vputs Time.now
  end
end # main

def compile( source_file_full_path, target_file_full_path, type )
  start_time = Time.now
  
  source_dir_full_path = File.dirname( source_file_full_path )
  counter = 0
  @o = Markup.new
  string = file_read( source_file_full_path )

  match, nomatch = @o.sections( string )
  nomatch.each_index { |i|
    next if nomatch[i] == nil
    nomatch[i] = @o.not_in_html( nomatch[i]                        ) { |i| @o.blocks(i)                }.join
    nomatch[i] = @o.not_in_html( nomatch[i]                        ) { |i| @o.HTML_horizontal_rules(i) }.join
    nomatch[i] = @o.not_in_html( nomatch[i]                        ) { |i| @o.markup_everything(i)     }.join
    nomatch[i] = @o.not_in_html( nomatch[i]                        ) { |i| @o.links_plain(i)           }.join
    nomatch[i] = @o.not_in_html( nomatch[i]                        ) { |i| @o.links_named(i)           }.join
    #nomatch[i] = @o.not_in_html( nomatch[i], source_file_full_path ) { |i,j| @o.links_local_new(i,j)       }.join
    #nomatch[i] = @o.not_in_html( nomatch[i], source_file_full_path ) { |i,j| @o.links_automatic(i,j)       }.join

    #nomatch[i]          = @o.blocks(                nomatch[i] )
    #nomatch[i]          = @o.HTML_horizontal_rules( nomatch[i] )
    #nomatch[i]          = @o.markup_everything(     nomatch[i] )
    #nomatch[i]          = @o.links_plain(           nomatch[i] )
    #nomatch[i]          = @o.links_named(           nomatch[i] )
    nomatch[i], counter = @o.links_numbered(        nomatch[i], '', '', '[', ']', counter )
    nomatch[i]          = @o.links_local_new(       nomatch[i], source_file_full_path )
    nomatch[i]          = @o.links_automatic(       nomatch[i], source_file_full_path )

    #nomatch[i]          = @o.lists(                 nomatch[i] )
    #nomatch[i]          = @o.paragraphs(            nomatch[i] )
    nomatch[i] = @o.not_in_html( nomatch[i] ) { |i| @o.lists(i) }.join
    nomatch[i] = @o.not_in_html( nomatch[i] ) { |i| @o.paragraphs(i) }.join
  }
  string = @o.recombine( match, nomatch ).join
  string = @o.header_and_footer( string, source_file_full_path, target_file_full_path, type )

  create_file( target_file_full_path, string )
  vputs "#{Time.now - start_time} seconds."
end


$VERBOSE = true
# TODO:  Check for an environment variable like $TEMP and use that instead!
#        I see nothing in ENV which I can use.  =/
pid_file = File.join( '', 'tmp', 'compile_child_pid' )
local_wiki  = File.join( Dir.pwd, 'src', 'w' )
local_blog  = File.join( Dir.pwd, 'src', 'b' )
remote_wiki = File.join( Dir.pwd, 'live' )
remote_blog = File.join( Dir.pwd, 'live', 'b' )

# md_directory( local_wiki )
# md_directory( local_blog )
# md_directory( remote_wiki )
# md_directory( remote_blog )

main( local_wiki, local_blog, remote_wiki, remote_blog, pid_file )


__END__

require File.join(Dir.pwd, 'rb/lib/lib_misc.rb')
require File.join(Dir.pwd, 'rb/lib/lib_files.rb')
file_read(File.join(Dir.pwd, 'source/wiki/compiled-website-demo.asc'))




Yield example.. passing a method name

def example_one
  return "This is example one"
end

def example_two
  return "This is example two"
end

def example_yield
  puts yield
end

example_yield() {
  example_one()
  #example_two()
}
