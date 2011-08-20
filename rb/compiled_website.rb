$slow = false
#$slow = true

=begin
should some variation of backticks allow auto-linking?

make an announcement mailing list - use the free thing which unity had at some point.

This is getting italicised completely:
-- /The [http://www.ruby-lang.org/en/ Ruby] 1.9 core and standard libraries.
This is showing the trailing slash:
-- /The [http://www.ruby-lang.org/en/ Ruby] 1.9 core and standard libraries./


This isn't working as expected, the bottom horizontal rule isn't being generated.:
___
Linux Software
 http://tidy.sourceforge.net
---
___

Some text isn't being properly merged together into one line.  For example:
___
But it's not finished and isn't available yet.  See the compiled website to do and compiled website bugs.
Coming soon:
___
however, this ends up being double-spaced:
___
But it's not finished and isn't available yet.  See the compiled website to do and compiled website bugs.

Coming soon:
___



Re-do the table of contents!

string
- list

string

There should only be one space between the string and the end of the list.  At the moment too much space is being shown.  Make the auto-paragraph stuff smarter about this?  Fix it elsewhere?

Lists are being processed within pre-blocks.  Whoops!  See ruby-arrays for an example.

The nesting doesn't properly go down by two:
- one
-- two
--- three
- FIXME:  one

My dashed line on the left-hand side isn't appearing!
- My div stuff hasn't been figured out?
- I'm not using html tidy am I?


Array.new.public_methods
Array.superclass.public_methods




a current limitation of sections is that at least one line has to be seen between them.
valid:
  = one =

  = two =
invalid:
  = one =
  = two =
.. should be straightforward to fix.


# Markup that's doable but which I don't care about.
# <sup> - Superscript
# <sub> - Subscript

implement indentation with :


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
    self.each_line { |ln| lines << ln }

    first_line_ws = lines[0].match( /^\s*/ )[0]
    rx = Regexp.new( '^\s{0,' + first_line_ws.length.to_s + '}' )

    lines.collect { |line| line.sub( rx, "" ) }.join
  end

  # like Array.partition, but "global", in the same sense that `sub` has `gsub`
  def gpartition( rx )
    a = self.partition( rx )
    until a[-1].match( rx ) == nil do
      a[-1] = a[-1].partition( rx )
      a.flatten!
    end
    # Returns an array
    # Odd are the non-matches
    # Even are the matches
    # Always returns an odd number of elements
    return a
  end
end


class Markup

  def split_string_html( string )
    # Regex thanks to
    #   http://www.regular-expressions.info/brackets.html
    #   Originally:  <([A-Z][A-Z0-9]*)\b[^>]*>.*?</\1>
    rx = %r{
      <                       (?# <html> )
      ([A-Za-z][a-zA-Z0-9]*)  (?# Valid html begins with a letter, then can a combination of letters and numbers. )
      \b                      (?# Word boundary, to support <foo bar="quux"> -type syntax. )
      [^>]*                   (?# This doesn't feel quite right. Technically the > character is legal within tags.  I think it works as expected/desired though. )
      >
      .*?                     (?# Anything:  .*  can be between the <html> and </html>, but don't be greedy:  ?  )
      <                       (?# </html> where 'html' must match the earlier <html>. )
        /
        \1
      >
    }mx

    return string.gpartition( rx )
  end

  def not_in_html( string, *splat )
    array = split_string_html( string )
    array.each_index { |i|
      next if i.odd?
      # I append a '' to ensure an odd length array.
      # No need to process that.
      break if i+1 == array.length and array[i] == ''
      array[i] = yield( array[i], splat )
    }
    return array
  end

  def punctuation_rx( left_rx, right_rx )
    # This would need to be reworked if it should match across lines.  But I don't think it should!
    # TODO:  Match across [ and ] ?
    punctuation_start=(%r{
      ^       (?# Line start)
      |\      (?# Space)
    }x)
    punctuation_start=(%r{
       #{ punctuation_start }
      |#{ punctuation_start } '
      |#{ punctuation_start } "
      |#{ punctuation_start } \(
      |#{ punctuation_start } --
    }x)
      
    punctuation_end=(%r{
      $     (?# Line end)
      |\    (?# Space)
    }x)
    punctuation_end=(%r{
            #{ punctuation_end }
      |\.   #{ punctuation_end }
      |,    #{ punctuation_end }
      |!    #{ punctuation_end }
      |:    #{ punctuation_end }
      |;    #{ punctuation_end }
      |\?   #{ punctuation_end }
      |--   #{ punctuation_end }
      |'    #{ punctuation_end }
      |"    #{ punctuation_end }
    }x)
    punctuation_end=(%r{
            #{ punctuation_end }
      |s    #{ punctuation_end }
      |es   #{ punctuation_end }
      |ed   #{ punctuation_end }
    }x)

    return %r{
      (#{ punctuation_start })
      (#{ left_rx })
      (.*?)
      (#{ right_rx })
      (#{ punctuation_end })
    }x
  end
  
  def punctuation_rx_single( rx )

      punctuation_start=(%r{
        ^       (?# Line start)
        |\      (?# Space)
      }x)
      punctuation_start=(%r{
         #{ punctuation_start }
        |#{ punctuation_start } '
        |#{ punctuation_start } "
        |#{ punctuation_start } \(
        |#{ punctuation_start } --
      }x)
        
      punctuation_end=(%r{
        $     (?# Line end)
        |\    (?# Space)
      }x)
      punctuation_end=(%r{
              #{ punctuation_end }
        |\.   #{ punctuation_end }
        |,    #{ punctuation_end }
        |!    #{ punctuation_end }
        |:    #{ punctuation_end }
        |;    #{ punctuation_end }
        |\?   #{ punctuation_end }
        |--   #{ punctuation_end }
        |'    #{ punctuation_end }
        |"    #{ punctuation_end }
      }x)
      punctuation_end=(%r{
              #{ punctuation_end }
        |s    #{ punctuation_end }
        |es   #{ punctuation_end }
        |ed   #{ punctuation_end }
      }x)

      return %r{
        (#{ punctuation_start })
        (#{ rx })
        (#{ punctuation_end })
      }mx
  end
  
  def markup( string, left_rx, right_rx, left_replace, right_replace )
    string = split_string_html( string )
    rx = punctuation_rx( left_rx, right_rx )
    string.each_index { |i|
      next if i.odd?
      next if string[i].match( rx ) == nil
      string[i].sub!( rx, $~[1] + left_replace + $~[3] + right_replace + $~[5] )
      string[i] = split_string_html( string[i] )
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

  def sections( string )
    array = split_string_sections( string )
    heading_level = 0
    heading_level_previous = 0
    array.each_index do |i|
      next if i.even?
      array[i].match( %r{(^=+)(\ )()(.*?)()(\ )(=+$)} )
      next if $~ == nil
      heading_level_previous = heading_level
      heading_level          = $~[1].length
      title = "<h#{ heading_level }>" + $~[4] + "</h#{ heading_level }>"
      array[i] = ""

      # The first section encountered does not have previous sections to close.
      if heading_level_previous == 0 then
        # But it is legal have the document's first section be larger than one.
        a = heading_level
        ( heading_level - heading_level_previous ).times do
          array[i] = "<div class=\"s#{ a }\">" + array[i]
          a -= 1
        end
        array[i] += title
        next
      end

      # stayed the same
      if heading_level == heading_level_previous then
        # Close the previous section.
        # Begin a new section.
        array[i] = "</div><div class=\"s#{ heading_level }\">" + title
        next
      end

      # If the heading level increased, then one or more additional sections must be declared.
      # No previous sections will be closed.
      if heading_level > heading_level_previous then
        a = heading_level
        ( heading_level - heading_level_previous ).times do
          array[i] = "<div class=\"s#{ a }\">" + array[i]
          a -= 1
        end
        array[i] += title
        next
      end

      # If the heading level decreased, then
      # 1) we must </div> to close off the appropriate number of previous sections.
      # 2) we must begin this new section
      if heading_level < heading_level_previous then
        a = heading_level
        ( heading_level_previous - heading_level + 1 ).times do
          array[i] = '</div>' + array[i]
        end
        array[i] = array[i] + "<div class=\"s#{ heading_level }\">" + title
        next
      end

    end # array.each_index do |i|

    # Close off previous sections, if any.
    # RECHECK
    if heading_level > 0 then
      heading_level.times do
        array[-1] += '</div>'
      end
    end

    return array
  end # def sections( string )

  def paragraphs( string )
    # TODO:  There's probably another way to do this, but a (2..10).each construct wasn't playing nice.
    string.gsub!( /\n{10}/, "</p>\n#{ "<br />\n" * 8 }<p>" )
    string.gsub!( /\n{9}/,  "</p>\n#{ "<br />\n" * 7 }<p>" )
    string.gsub!( /\n{8}/,  "</p>\n#{ "<br />\n" * 6 }<p>" )
    string.gsub!( /\n{7}/,  "</p>\n#{ "<br />\n" * 5 }<p>" )
    string.gsub!( /\n{6}/,  "</p>\n#{ "<br />\n" * 4 }<p>" )
    string.gsub!( /\n{5}/,  "</p>\n#{ "<br />\n" * 3 }<p>" )
    string.gsub!( /\n{4}/,  "</p>\n#{ "<br />\n" * 2 }<p>" )
    string.gsub!( /\n{3}/,  "</p>\n#{ "<br />\n" * 1 }<p>" )
    string.gsub!( /\n{2}/,  "</p>\n#{ "<br />\n" * 0 }<p>" )
    return '<p>' + string + '</p>'
  end

  def horizontal_rules( string )
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
    oldverbose = $VERBOSE
    $VERBOSE = nil

    def files_array( source_file_full_path )
      files_array = Dir[ File.dirname( source_file_full_path ) + '/*.asc' ]
      files_array.delete_if { |x|
        (
          # The current source file is not a valid link target.
          x == source_file_full_path \
        or
          # Only process files.
          # TODO:  I should write a test case for this.
          File.file?( x ) != true
        )
      }
      return files_array
    end

    def rx( file )
      # '/foo/bar/one-two-three.asc' => [ 'one', 'two', 'three' ]
      basename = File.basename( file, '.asc' ).split( %r{-} )
      # [ 'one', 'two', 'three' ] => %r{ one[-| ]two[-| ]three }
      # This allows matching things like 'compiled website' or 'compiled-website'.
      rx = %r{ #{ basename[0] } }ix
      basename.each_index { |i|
        next if i == 0
        rx = %r{ #{ rx }[-|\ ]#{ basename[i] } }ix
      }
      basename = nil
      # TODO
      if $slow == true then
        rx = punctuation_rx_single( rx )
      else
        rx = %r{ ()(#{ rx })() }ix
      end
      return rx
    end

    files_array( source_file_full_path ).each{ |file|
      string_array = split_string_html( string )
      string = nil
      string_array.each_index { |e|
        next if e.odd?
        string_array[e] = string_array[e].sub(
          rx( file ),
          '\1<a href="' + File.basename( file, '.asc' ) + '.html">\2</a>\3',
        )
        # If I've found a match for this file, don't bother looking through other strings.  Break out and continue to the next file.
        break if $~ != nil
      }
      string = string_array.join
      string_array = nil
    }
    $VERBOSE = oldverbose
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
          create_file( new_source_file_full_path )
        end
      end # File.exist?( new_source_file_full_path ) and File.size( new_source_file_full_path ) > 0 then
    end # string.match( rx ) == nil do
    return string
  end

  # TODO:  Add another flag which will not merge multiple matched lines together into one array-element.
  def split_string_by_line( string, rx, spaces )
    if not string.match( rx ) then
      return [ string ]
    end

    result = [ '' ]
    matched = false
    matchedtwice = false
    string.each_line{ |line|
      if line.match( rx ) then
        result << '' if matched == false
        result[-1] += line.lstrip
        matched = true
      else # this line doesn't match.
        # If the previous line was a match, and the current line is \n, then omit this line..
        if matched == true and line == "\n" and matchedtwice == false and spaces == true then
          # do nothing
          # but allow a consecutive match to append.
          matched = true
          # however, don't do this for every single \n, just one.
          matchedtwice = true
        else
          result << '' if matched == true
          result[-1] += "\n" if matchedtwice == true and spaces == true
          result[-1] += line
          matched = false
        end
      end
    }
    return result
  end

  def lists_arrays( string )
    return split_string_by_line( string, %r{^\ *[-|\#]+\ +.+?$}, true )
  end

  def split_string_sections( string )
    rx = %r{^=+\ .*?\ =+$}
    return split_string_by_line( string, rx, false )
  end

  def lists_initial_increase( two, string )
    close_tally = Array.new
    if    two[0] == '-' then
      c = 'u'
    elsif two[0] == '#' then
      c = 'o'
    end
    if two.length == 1 then
      open = "<#{ c }l>\n<li>"
      close_tally << "\n</#{ c }l>"
    else
      open = ( "<#{ c }l>\n<li>\n" * two.length ).chomp
      two.length.times do
        close_tally << "\n</#{ c }l>\n</li>"
      end
      close_tally[-1] = close_tally[-1].chomp( '</li>' ).chomp
    end
    return open + string, close_tally
  end

  def lists_increase( two, string, delta, close_tally )
    if    two[0] == '-' then
      c = 'u'
    elsif two[0] == '#' then
      c = 'o'
    end
    open = "\n<#{ c }l>\n<li>" * delta
    open = open[1..-1]
    delta.times do
      close_tally.insert( 0, "\n</#{ c }l>\n</li>" )
    end

    return open + string, close_tally
  end

  def lists( string )
#puts "\n\n---v"
    rx = %r{^(\ *)([-|\#]+)(\ +)(.+)$}
    # This works for single items only, and a whole new thing had to be made to handle consecutive matches.
    # array = split_string( string, rx )
    #array = split_string( string, rx )
    array = lists_arrays( string )

#puts 'i:j   item      nesting type'
#puts '---   ----      ------- ----'


    array.each_index { |i|
#      next if array[i] == nil
      next if i.even?
      current_list = array[i].split( "\n" )
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
      array[i] = current_list.join( "\n" )
    } # i (the array of lists)
#puts "---^\n\n"
    #return array.join( "\n" )
    return array.join
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

  def compile_main( string, source_file_full_path, target_file_full_path, type='wiki' )
    counter = 0
    string = sections( string )
    string.each_index { |i|
      next if i.odd?

      #string[i] = not_in_html( string[i]                        ) { |i| blocks(i)                }.join
      #string[i] = not_in_html( string[i]                        ) { |i| horizontal_rules(i) }.join
      #string[i] = not_in_html( string[i]                        ) { |i| markup_everything(i)     }.join
      #string[i] = not_in_html( string[i]                        ) { |i| links_plain(i)           }.join
      #string[i] = not_in_html( string[i]                        ) { |i| links_named(i)           }.join
    
      # FIXME:  These two can't work this way.  For example, rsync will explode with links_local_new
      # I'm not sure what I meant.  Re-examine this.
      #string[i] = not_in_html( string[i], source_file_full_path ) { |i,j| links_local_new(i,j)       }.join
      #string[i] = not_in_html( string[i], source_file_full_path ) { |i,j| links_automatic(i,j)       }.join
    
      string[i]          = blocks(            string[i] )
      string[i]          = horizontal_rules(  string[i] )
      string[i]          = markup_everything( string[i] )
      string[i]          = links_plain(       string[i] )
      string[i]          = links_named(       string[i] )
    
      string[i], counter = links_numbered(    string[i], '', '', '[', ']', counter )
    
      string[i]          = links_local_new(   string[i], source_file_full_path )
      string[i]          = links_automatic(   string[i], source_file_full_path )
    
      string[i]          = lists(             string[i] )
      string[i]          = paragraphs(        string[i] )
      #string[i] = not_in_html( string[i] ) { |i| lists(i) }.join
      #string[i] = not_in_html( string[i] ) { |i| paragraphs(i) }.join
    }
    string = string.join
    string = header_and_footer( string, source_file_full_path, target_file_full_path, type )
    return string
  end

end # class Markup

class Test_Markup < MiniTest::Unit::TestCase

  def setup()
    @o = Markup.new
  end

  def test_split_string()
    # Odd matches.
    # Even does not match.
    # Always an even number of elements.

    string = 'nothing'
    expected = [
      string,
      '',
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    string = '<a>html</a>'
    expected = [
      '',
      string,
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Trailing html tags are counted as strings.
    string = '<a>html</a><a>'
    expected = [
      '',
      '<a>html</a>',
      '<a>',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Valid HTML has content within the tags.
    string = '<>html</>'
    expected = [
      string,
      '',
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Valid HTML has matching content within the tags.
    string = '<a>html</b>'
    expected = [
      string,
      '',
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Text before and after.
    string = 'before <a>html</a> after'
    expected = [
      'before ',
      '<a>html</a>',
      ' after',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Multiple instances of HTML.
    string = 'before <a>html</a> during <b>more html</b> after'
    expected = [
      'before ',
      '<a>html</a>',
      ' during ',
      '<b>more html</b>',
      ' after',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Multiple instances of the same HTML tags.
    string = '<strong>one</strong> during <strong>two</strong>'
    expected = [
      '',
      '<strong>one</strong>',
      ' during ',
      '<strong>two</strong>',
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Nested HTML.
    string = 'before <strong>STRONG <em>STRONG-EMPHASIS</em> BOLD</strong> not markup <strong>STRONG</strong> after'
    expected = [
      'before ',
      '<strong>STRONG <em>STRONG-EMPHASIS</em> BOLD</strong>',
      ' not markup ',
      '<strong>STRONG</strong>',
      ' after',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Improperly-nested instances of the same HTML tags.
    # This is user-error and is invalid HTML.
    #   TODO:  Check, is it invalid?  Isn't nesting tags valid?
    # HTML Tidy can clean this kind of code up.
    # TODO:  It would be nice to be able to deal with this sort of problem, but perhaps I can use HTML tidy on blocks of code before processing them myself.
=begin
    string = 'before <strong>one <strong>two </strong></strong> after'
    # In a perfect world, we could do this.
    expected = [
      'before ',
      '<strong>one <strong>two </strong></strong>',
      ' after',
    ]
    # However in reality, this is what we're getting.
    expected = [
      'before ',
      '<strong>one <strong>two </strong>',
      '</strong> after',
    ]

    # proper HTML would not have nesting and would look like this:
    string = 'before <strong>one </strong><strong>two </strong> after'

    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }
=end

    # Garbage.
    string = '<foo bar="baz > quux">no</bar> yes </baz>no</>'
    expected = [
      string,
      '',
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Painfully complex.
    string = '<tag bar="baz > quux">no</tag>'
    expected = [
      '',
      string,
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Mind-numbingly complex.
    string = '<tag bar="</tag>">text</tag>'
    expected = [
      '',
      string,
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    string = "<a></a>DISPLAY<b></b> <a href=\"foo.html\">foo</a>"
    expected = [
      '',
      '<a></a>',
      'DISPLAY',
      '<b></b>',
      ' ',
      "<a href=\"foo.html\">foo</a>",
      '',
    ]
$a = true
    result = @o.split_string_html( string )
$a = false
#p result
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }


  end

  def test_not_in_html()
    # Note that more complex testing has already been done within test_split_string()
    # So I'm not getting too complex here, but just testing the not_in_html_test_method() use of yield.
    def not_in_html_test_method( string, *array )
      if array.size > 0 then
        append = ' ' + array[0..-1].join( ' ' )
      else
        append = ''
      end
      string = "{#{ string }}#{append}"
      return string
    end
    string = 'one'
    expected = '{one}'
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i ) }.join
    assert_equal(
      expected,
      result,
    )
    # Remember that <> and </> are not proper HTML.
    string = 'one <>two</>'
    expected = '{one <>two</>}'
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i ) }.join
    assert_equal(
      expected,
      result,
    )
    string = 'one <em>two</em>'
    expected = '{one }<em>two</em>'
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i ) }.join
    assert_equal(
      expected,
      result,
    )
    string = 'one <em>two</em> three'
    expected = '{one }<em>two</em>{ three}'
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i ) }.join
    assert_equal(
      expected,
      result,
    )
    string = 'one <em>two</em> three <em>four</em> five'
    expected = [
      '{one }',
      '<em>two</em>',
      '{ three }',
      '<em>four</em>',
      '{ five}',
      '',
    ]
    result  = @o.not_in_html( string ) { |i| not_in_html_test_method(  i        ) }
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }
    string = 'one <em>two</em> three <em>four</em> five'
    expected = [
      '{one } hey more',
      '<em>two</em>',
      '{ three } hey more',
      '<em>four</em>',
      '{ five} hey more',
      '',
    ]
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i, 'hey', 'more' ) }
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }
    string = <<-heredoc.unindent
      <em>
        html
      </em>
      regular text
    heredoc
    expected = [
      "{}",                  # 0
      ( <<-heredoc.unindent  # 1
        <em>
          html
        </em>
      heredoc
      ).chomp,
      ( <<-heredoc.unindent  # 3
        {
        regular text
        }
      heredoc
      ).chomp,
      '',                    # 4
    ]
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i ) }
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }
  end

  def test_markup_underline()

    #
    string = '_underlined_'
    expected = '<u>underlined</u>'
    result = @o.markup_underline( string )
    assert_equal(
      expected,
      result,
    )

    #
    string = 'one _two_ three _four_'
    expected = 'one <u>two</u> three <u>four</u>'
    result = @o.markup_underline( string )
    assert_equal(
      expected,
      result,
    )

    #
    string = '<> _not underlined_ </>'
    assert_equal(
      string,
      @o.markup_underline( string ),
    )

    #
    string = '<>_not underlined_</>'
    assert_equal(
      string,
      @o.markup_underline( string ),
    )

    #
    string = <<-heredoc.unindent
        _not
        underlined_
      heredoc
    assert_equal(
      string,
      @o.markup_underline( string ),
    )

    #
    string = <<-heredoc.unindent
        <em>
        _not underlined_
        </em>
      heredoc
    assert_equal(
      string,
      @o.markup_underline( string ),
    )

    #
    string = '<em>_not underlined_</em>'
    assert_equal(
      string,
      @o.markup_underline( string ),
    )

    #
    string = <<-heredoc.unindent
      <em>
      _not underlined_
      </em>
      <em>
      _not underlined_
      </em>
    heredoc
    assert_equal(
      string,
      @o.markup_underline( string ),
    )

    # This is another case of improperly-nested html tags.
    # It's mentioned within test_split_string()
=begin     
    string = <<-heredoc.unindent
      <em>
        <em>
          _not underlined_
        </em>
        _not underlined_
      </em>
    heredoc
    assert_equal(
      string,
      @o.markup_underline( string ),
    )
=end
  end

  def test_multiple_everything()
    assert_equal(
      '<u>underlined</u> and <strong>strong</strong>',
      @o.markup_everything( '_underlined_ and *strong*' ),
    )
  end

  def test_nested_markup()
    # This demonstrates how the first markup's html-result will stop any future markup from acting within that html.
    assert_equal(
      '<u>*underlined*</u> <strong>strong</strong>',
      @o.markup_everything( @o.markup_underline( '_*underlined*_ *strong*' ) ),
    )
  end

  def test_big()
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

  def test_sections()

    #
    string = <<-heredoc.unindent
      This is an example document.
    heredoc
    expected = [
      "This is an example document.\n",
    ]
    result = @o.split_string_sections( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    #
    string = <<-heredoc.unindent
      = Title One =
    heredoc
    expected = [
      '',
      "= Title One =\n",
    ]
    result = @o.split_string_sections( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    #
    string = <<-heredoc.unindent
      This is an example document.
      
      = Title One =
      
      Text in section one.
      
      = Title Two =
      
      Text in section two.
    heredoc
    expected = [
      "This is an example document.\n\n",
      "= Title One =\n",
      "\nText in section one.\n\n",
      "= Title Two =\n",
      "\nText in section two.\n",
    ]
    result = @o.split_string_sections( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    string = <<-heredoc.unindent
      = 1 =
      THIS SHOULD APPEAR
      = 2 =
      
      = 3 =
    heredoc
    expected = [
      '',
      "= 1 =\n",
      "THIS SHOULD APPEAR\n",
      "= 2 =\n",
      "\n",
      "= 3 =\n",
    ]
    result = @o.split_string_sections( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    result.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    #
    string = <<-heredoc.unindent
      = 1 =
    heredoc
    expected = <<-heredoc.unindent
      <div class="s1"><h1>1</h1></div>
    heredoc
    result = @o.sections( string ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )

    #
    string = <<-heredoc.unindent
      === 3 ===
    heredoc
    expected = <<-heredoc.unindent
      <div class="s1"><div class="s2"><div class="s3"><h3>3</h3></div></div></div>
    heredoc
    result = @o.sections( string ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )

    #
    string = <<-heredoc.unindent
      = 1 =
      
      = 2 =
    heredoc
    expected = <<-heredoc.unindent
      <div class="s1"><h1>1</h1>
      </div><div class="s1"><h1>2</h1></div>
    heredoc
    result = @o.sections( string ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )

    #
    string = <<-heredoc.unindent
      = 1 =
      
      == 2 ==
    heredoc
    expected = <<-heredoc.unindent
      <div class="s1"><h1>1</h1>
      <div class="s2"><h2>2</h2></div></div>
    heredoc
    result = @o.sections( string ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )

    #
    string = <<-heredoc.unindent
      = 1 =
      
      === 3 ===
    heredoc
    expected = <<-heredoc.unindent
      <div class="s1"><h1>1</h1>
      <div class="s2"><div class="s3"><h3>3</h3></div></div></div>
    heredoc
    result = @o.sections( string ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )

    #
    string = <<-heredoc.unindent
      == 2 ==
      
      ==== 4 =====
    heredoc
    expected = <<-heredoc.unindent
      <div class="s1"><div class="s2"><h2>2</h2>
      <div class="s3"><div class="s4"><h4>4</h4></div></div></div></div>
    heredoc
    result = @o.sections( string ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )

    #
    string = <<-heredoc.unindent
      == 2 ==
      
      = 1 =
    heredoc
    expected = <<-heredoc.unindent
      <div class="s1"><div class="s2"><h2>2</h2>
      </div></div><div class="s1"><h1>1</h1></div>
    heredoc
    result = @o.sections( string ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )

    #
    string = <<-heredoc.unindent
      === 3 ===
      
      = 1 =
    heredoc
    expected = <<-heredoc.unindent
      <div class="s1"><div class="s2"><div class="s3"><h3>3</h3>
      </div></div></div><div class="s1"><h1>1</h1></div>
    heredoc
    result = @o.sections( string ).join + "\n"
    assert_equal(
      ( expected ),
      ( result ),
    )
  end

  def test_paragraphs()
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

  def test_horizontal_rules()
    assert_equal(
      ( <<-heredoc.unindent
        line one
      heredoc
      ),
      @o.horizontal_rules( <<-heredoc.unindent
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
      @o.horizontal_rules( <<-heredoc.unindent
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
      @o.horizontal_rules( <<-heredoc.unindent
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
      @o.horizontal_rules( <<-heredoc.unindent
        Test >
        ---
        
        content
      heredoc
      ),
    )

  end

  def test_links_plain()
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

  def test_links_named()
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

  def test_links_numbered()
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
  def test_links_automatic()
    verbose_old = $VERBOSE
    $VERBOSE = false
    create_file( '/tmp/foo.asc' )
    create_file( '/tmp/bar.asc' )
    create_file( '/tmp/foo-bar.asc' )
    create_file( '/tmp/compiled-website-test-file.asc' )

    # Simple match
    string = <<-heredoc.unindent
      foo
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo.html">foo</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Case-insensitive match.
    string = <<-heredoc.unindent
      Foo
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo.html">Foo</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Only link the first word.
    string = <<-heredoc.unindent
      foo foo
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo.html">foo</a> foo
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Only link the first word.
    string = <<-heredoc.unindent
      foo <a href="a">a</a> foo
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo.html">foo</a> <a href="a">a</a> foo
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    #
    string = <<-heredoc.unindent
      bar
    heredoc
    expected = <<-heredoc.unindent
      <a href="bar.html">bar</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Links two words, and don't link single words.
    string = <<-heredoc.unindent
      foo bar
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo-bar.html">foo bar</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Multi-word matches
    string = <<-heredoc.unindent
      compiled website test file
    heredoc
    expected = <<-heredoc.unindent
      <a href="compiled-website-test-file.html">compiled website test file</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Multi-word matches, where there are dashes.
    string = <<-heredoc.unindent
      compiled-website test file
    heredoc
    expected = <<-heredoc.unindent
      <a href="compiled-website-test-file.html">compiled-website test file</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Working with single words then removing them as possibilities.
    string = <<-heredoc.unindent
      foo
      bar foo bar
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo.html">foo</a>
      <a href="bar.html">bar</a> <a href="foo-bar.html">foo bar</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Allow matching within punctuation and specific endings
    string = <<-heredoc.unindent
      fooed
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo.html">foo</a>ed
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Match, ignoring dashes in the source text.
    string = <<-heredoc.unindent
      compiled-website test file
    heredoc
    expected = <<-heredoc.unindent
      <a href="compiled-website-test-file.html">compiled-website test file</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Don't link the current document's name.
    string = <<-heredoc.unindent
      foo
    heredoc
    expected = <<-heredoc.unindent
      foo
    heredoc
    source_file_full_path = '/tmp/foo.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Prioritizing two words before single words.
    string = <<-heredoc.unindent
      foo bar foo bar
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo-bar.html">foo bar</a> <a href="foo.html">foo</a> <a href="bar.html">bar</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # Multiple separate matches.
    string = <<-heredoc.unindent
      bar foo
    heredoc
    expected = <<-heredoc.unindent
      <a href="bar.html">bar</a> <a href="foo.html">foo</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    # FIXME:  There's a serious speed issue here.  =(  This may be impossible to fix, or it could be a regex thing.
    # Do not allow matching within words.
    # Maybe I can still have improved matching without being too slow.  I don't want to match the 'pre' in 'preview' and so I could still require at least a small subset of punctuation can't i?  Investigate.
    if $slow == true then
      string = <<-heredoc.unindent
        abcfoodef
      heredoc
      expected = <<-heredoc.unindent
        abcfoodef
      heredoc
      source_file_full_path = '/tmp/something.asc'
      result = @o.links_automatic( string, source_file_full_path )
      assert_equal(
        expected,
        result,
      )
    end

    string = '<a></a>DISPLAY<b></b> foo'
    expected = '<a></a>DISPLAY<b></b> <a href="foo.html">foo</a>'
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal(
      expected,
      result,
    )

    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/bar.asc' )
    File.delete( '/tmp/foo-bar.asc' )
    File.delete( '/tmp/compiled-website-test-file.asc' )

    $VERBOSE = verbose_old
  end

  # Naughty tests touch the disk.
  def test_links_local_new()
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
    create_file( '/tmp/bar.asc' )
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
  def test_links_mixed()
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
    assert_equal(
      '<a class="new" href="file:///tmp/bar.asc">bar</a> <a href="baz.html">baz</a> <a class="new" href="file:///tmp/quux.asc">quux</a>',
      @o.links_automatic(
        @o.links_local_new( 
          file_read( filename ),
          filename,
        ),
        filename,
      ),
    )
    File.delete( '/tmp/bar.asc' )
    File.delete( '/tmp/quux.asc' )

    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/baz.asc' )

    $VERBOSE = verbose_old
  end

  def test_lists_arrays()

    #
    string = <<-heredoc.unindent
      foo
    heredoc
    expected = [
      string,
    ]
    result = @o.lists_arrays( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    expected.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    #
    string = <<-heredoc.unindent
      - one
    heredoc
    expected = [
      '',
      string,
    ]
    result = @o.lists_arrays( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    expected.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    #
    string = <<-heredoc.unindent
      # one
    heredoc
    expected = [
      '',
      string,
    ]
    result = @o.lists_arrays( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    expected.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    #
    string = <<-heredoc.unindent
      before
      - one
    heredoc
    expected = [
      "before\n",
      "- one\n",
    ]
    result = @o.lists_arrays( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    expected.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    #
    string = <<-heredoc.unindent
      before
      - one
      after
    heredoc
    expected = [
      "before\n",
      "- one\n",
      "after\n",
    ]
    result = @o.lists_arrays( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    expected.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Multiple list items in a row.
    string = <<-heredoc.unindent
      - one
      - two
    heredoc
    expected = [
      '',
      "- one\n- two\n",
    ]
    result = @o.lists_arrays( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    expected.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Multiple list items in a row.  Mixed types.
    string = <<-heredoc.unindent
      - one
      # two
    heredoc
    expected = [
      '',
      "- one\n# two\n",
    ]
    result = @o.lists_arrays( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    expected.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Single blank lines are allowed, but removed, merging the lists.
    string = <<-heredoc.unindent
      - one
      
      - two
      - three
    heredoc
    expected = [
      '',
      "- one\n- two\n- three\n",
    ]
    result = @o.lists_arrays( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    expected.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Multiple blank lines form separate lists.
    string = <<-heredoc.unindent
      - one
      
      
      - two
      - three
    heredoc
    expected = [
      '',
      "- one\n",
      "\n\n",
      "- two\n- three\n",
    ]
    result = @o.lists_arrays( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    expected.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

    # Indentation is allowed, but removed.
    string = <<-heredoc
      - one
      
      
      - two
      - three
    heredoc
    expected = [
      '',
      "- one\n",
      # yes, the whitespace is kept for the non-list lines.
      "      \n      \n",
      "- two\n- three\n",
    ]
    result = @o.lists_arrays( string )
    assert_equal(
      expected.size.to_s,
      result.size.to_s,
    )
    expected.each_index{ |i|
      assert_equal(
        expected[i],
        result[i],
      )
    }

  end

  def test_lists()

    #
    string = <<-heredoc.unindent
      foo
    heredoc
    expected = <<-heredoc.unindent
      foo
    heredoc
    result = @o.lists( string )
    assert_equal(
      expected,
      result,
    )

    #
    string = <<-heredoc.unindent
      - one
    heredoc
    expected = <<-heredoc.unindent
      <ul>
      <li>one</li>
      </ul>
    heredoc
    expected.chomp!
    result = @o.lists( string )
    assert_equal(
      expected,
      result,
    )

    #
    string = <<-heredoc.unindent
      # one
    heredoc
    expected = <<-heredoc.unindent
      <ol>
      <li>one</li>
      </ol>
    heredoc
    expected.chomp!
    result = @o.lists( string )
    assert_equal(
      expected,
      result,
    )

    #
    string = <<-heredoc.unindent
      before
      - one
      after
    heredoc
    expected = <<-heredoc.unindent
      before
      <ul>
      <li>one</li>
      </ul>after
    heredoc
    result = @o.lists( string )
    assert_equal(
      expected,
      result,
    )

    #
    string = <<-heredoc.unindent
      - one
      - two
    heredoc
    expected = <<-heredoc.unindent
      <ul>
      <li>one</li>
      <li>two</li>
      </ul>
    heredoc
    expected.chomp!
    result = @o.lists( string )
    assert_equal(
      expected,
      result,
    )

    # Single blank lines are combined.
    string = <<-heredoc.unindent
      - one
      
      - two
    heredoc
    expected = <<-heredoc.unindent
      <ul>
      <li>one</li>
      <li>two</li>
      </ul>
    heredoc
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

    # Allow indentation
    string = <<-heredoc
      - one
      - two
    heredoc
    expected = <<-heredoc.unindent
      <ul>
      <li>one</li>
      <li>two</li>
      </ul>
    heredoc
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

    # Allow indentation /and/ spaces.  Lists separated by single blank lines are combined.
    string = <<-heredoc
      - one
      
      - two
    heredoc
    expected = <<-heredoc.unindent
      <ul>
      <li>one</li>
      <li>two</li>
      </ul>
    heredoc
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

    # Allow indentation.  Lists separated by two blank lines are separate lists.
    string = <<-heredoc
      - one
      
      
      - two
    heredoc
    expected = <<-heredoc.unindent
      <ul>
      <li>one</li>
      </ul>
      
      
      <ul>
      <li>two</li>
      </ul>
    heredoc
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

    # Nested lists.
    string = <<-heredoc.unindent
      - one
      -- two
    heredoc
    expected = <<-heredoc.unindent
      <ul>
      <li>one
      <ul>
      <li>two</li>
      </ul>
      </li>
      </ul>
    heredoc
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

    # Nested lists, changing type
    string = <<-heredoc.unindent
      - one
      ## two
    heredoc
    expected = <<-heredoc.unindent
      <ul>
      <li>one
      <ol>
      <li>two</li>
      </ol>
      </li>
      </ul>
    heredoc
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

    # Initial list is nested
    string = <<-heredoc.unindent
      -- one
    heredoc
    expected = <<-heredoc.unindent
      <ul>
      <li>
      <ul>
      <li>one</li>
      </ul>
      </li>
      </ul>
    heredoc
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

    # Initial list is nested a lot
    string = <<-heredoc.unindent
      --- one
    heredoc
    expected = <<-heredoc.unindent
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
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

    # Nested lists, incrementing then decrementing
    string = <<-heredoc.unindent
      - one
      -- two
      - three
    heredoc
    expected = <<-heredoc.unindent
      <ul>
      <li>one
      <ul>
      <li>two</li>
      </ul>
      </li>
      <li>three</li>
      </ul>
    heredoc
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

    # Nesting lists, incrementing a lot.
    string = <<-heredoc.unindent
      - one
      --- two
    heredoc
    expected = <<-heredoc.unindent
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
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

    # Nesting lists, incrementing even more.
    string = <<-heredoc.unindent
      - one
      ---- two
    heredoc
    expected = <<-heredoc.unindent
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
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

    # Nesting lists, incrementing a lot, then decrementing a lot.
    string = <<-heredoc.unindent
      - one
      --- two
      - three
    heredoc
    expected = <<-heredoc.unindent
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
      <li>three</li>
      </ul>
    heredoc
    result = @o.lists( string )
    #assert_equal(
      #expected,
      #result,
    #)

=begin
    # TODO:  Mixed lists
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>one</li>
        </ul>
        <ol>
        <li>two</li>
        </ol>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
        - foo
        # bar
      heredoc
      ),
    )

# TODO:  Mixed lists, incrementing a lot.
# TODO:  Mixed lists, incrementing then decrementing a lot.

    # And now let's try to break the damned thing!
    assert_equal(
      ( <<-heredoc.unindent
        <ul>
        <li>
        <ul>
        <li>one</li>
        </ul>
        </li>
        </ul>
        <ol>
        <li>
        <ol>
        <li>two</li>
        </ol>
        </li>
        </ol>
        <ul>
        <li>three
        <ul>
        <li>four
        <ul>
        <li>five</li>
        </ul>
        </li>
        </ul>
        </li>
        </ul>
        <ol>
        <li>oh
        <ol>
        <li>
        <ol>
        <li>here</li>
        </ol>
        </li>
        </ol>
        </li>
        </ol>
      heredoc
      ).chomp,
      @o.lists( <<-heredoc.unindent
      -- one
      ## two
      - three
      -- four
      --- five
      -----
      # oh
      ### here
      heredoc
      ),
    )
=end
  end

  def test_blocks_arrays()

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
  
  def test_blocks()
  
    string = <<-heredoc.unindent
      foo
    heredoc
    expected = <<-heredoc.unindent
      foo
    heredoc
    result = @o.blocks( string )
    assert_equal(
      expected,
      result,
    )
  
    string = <<-heredoc.unindent
      before
        some text
    heredoc
    expected = <<-heredoc.unindent
      before
      <pre>some text
      </pre>
    heredoc
    expected.chomp!
    result = @o.blocks( string )
    assert_equal(
      expected,
      result,
    )
  
    string = <<-heredoc.unindent
      before
        some text
      after
    heredoc
    expected = <<-heredoc.unindent
      before
      <pre>some text
      </pre>after
    heredoc
    #expected.chomp!
    result = @o.blocks( string )
    assert_equal(
      expected,
      result,
    )
  
    string = <<-heredoc.unindent
      before
        some text
          indented text
      after
    heredoc
    expected = <<-heredoc.unindent
      before
      <pre>some text
        indented text
      </pre>after
    heredoc
    #expected.chomp!
    result = @o.blocks( string )
    assert_equal(
      expected,
      result,
    )
  
  end

end # class Test_Markup < MiniTest::Unit::TestCase

# The below code was mostly copied from the first generation of this codebase.
# ---


def create_file( file, file_contents='' )
  # TODO: This can't create a file if it's in a subdirectory that doesn't exist.  I get a TypeError.  Perhaps I could intelligently create the directory..
  vputs "creating file:  '#{ file }'"
  # TODO: check that I have write access to my current directory.
  # TODO: check for overwriting an existing file.  Also implement an optional flag to overwrite it.
  begin
    File.open( file, 'w+' ) { |f| # open file for update
      f.print file_contents       # write out the example description
    }                             # file is automatically closed
  rescue Exception
    # TODO:  Causes issues, but I'm not sure why.
#    raise "\nCreating the text file #{ file.inspect } has failed with: "
  end
end

def vputs( string )
  if $VERBOSE == true || $VERBOSE == nil then
    puts string
  end
end

def cd_directory( directory )
  # TODO:  I have not done proper testing on any of this.  I don't even know if "raise" works.
  # This is the equivalent of:  directory = exec( "readlink", "-f", Dir.getwd )
  directory = File.expand_path( directory )
  start_directory = Dir.getwd

  # TODO: Check permissions
  if directory == start_directory then
    vputs "cd_directory: Already in that directory:  '#{ directory }'"
    return 0
  end
  if not File.directory?(directory) then
    raise "cd_directory: Not a directory:  '#{ directory }'"
    return 1
  end
  if not File.exists?(directory) then
    raise "cd_directory: Directory doesn't exist:  '#{ directory }'"
    return 1
  end

  vputs "cd_directory: Entering directory:  '#{ directory }'"
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
  directory = File.expand_path( directory )
  if File.exists?( directory ) then
    if File.directory?( directory ) then
      # All is good!
      return 0
    else
      raise "md_directory: It's a file, I can't make a directory of the same name!:  #{ directory.inspect}"
      return 1
    end
  end
  # TODO:  Suppress explosions using Signal.trap, and deal with things gracefully.
  #        e.g.  Signal.trap( "HUP" ) { method() }
  #        Apply this technique elsewhere/everywhere.
  vputs "md_directory: making directory:  #{ directory.inspect}"

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
  Dir[ pid_file + '**' ].each do |file|
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
        vputs "pid #{ $$} was killed."
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
    vputs "started pid:  #{ $$}"
#    until "sky" == "falling" do
    loop do
#       vputs "pid #{ $$} sleeping"
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
    puts "process #{ $$} is working:  #{ Time.now}"
  }
end
#test_fork()
# Once your done testing, comment out test_fork and uncomment this.  It'll kill the one remaining fork.
# fork_killer( File.join( '', 'tmp', 'test_fork_pid' ) )

def file_read( file )
  vputs "Reading file:  '#{ file }'"
  # I suspect that there are issues reading files with a space in them.  I'm having a hard time tracking it down though.. TODO: I should adjust the test case.
  if ! File.exists?( file ) then
    puts "That file doesn't exist:  '#{ file.inspect }'"
    return
  end
  # TODO: Check permissions, etc.
# file = file.sub( ' ', '_' )
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
  working_file = "/tmp/test_file_read.#{ $$}"
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
    vputs "   Source: #{ source_file} to #{ stime}"
    vputs "   Target: #{ target_file} to #{ ttime}"
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
# FIXME:  Whoa, these dependencies need to be removed!
  lib = File.join( '', 'home', 'user', 'bin', 'rb', 'lib' )
  require File.join( lib, 'mine', 'misc.rb' )
  require File.join( lib, 'mine', 'strings.rb' )
  require File.join( lib, 'mine', 'directories.rb' )
  require File.join( lib, 'mine', 'files.rb' )
  # $$ is the pid of the current process.  That should make this safer.
  working_dir = File.join( '', 'tmp', "test_timestamp_sync.#{ $$}" )
  source_file = File.join( working_dir, 'source' )
  target_file = File.join( working_dir, 'target' )
  # Preparing directories
  md_directory( working_dir)
  # Preparing files
  create_file( source_file, 'content' )
  # Sleep, to force the timestamp to be wrong
  sleep 1.5
  create_file( target_file, 'content' )
  # NOTE: The following code is not portable!
  system( "\ls", "-lG", "--time-style=full-iso", working_dir )

  # Test
  puts " # First pass."
  timestamp_sync( source_file, target_file )
  puts " # Second pass."
  timestamp_sync( source_file, target_file )
  puts " # There should be no output."
  # Teardown
  # FIXME: Trap all errors and then perform my cleanup.  Fix all my test scripts to do this.
  # NOTE: The following code is not portable!
  system( '\ls', '-lG', '--time-style=full-iso', working_dir )
  rm_directory( working_dir )
end # test_timestamp_sync

def generate_sitemap( target_file_full_path, local_dir, source_file_full_path, type='wiki' )
  return 0
end


def main( local_wiki, local_blog, remote_wiki, remote_blog, pid_file )
  def process( local_dir, source_file_full_path, target_file_full_path, type='wiki' )
    compile(        source_file_full_path, target_file_full_path, type )
    timestamp_sync( source_file_full_path, target_file_full_path )
    # TODO:  Re-compile all files in that same source directory, to ensure that automatic linking is re-applied to include this new file.  Ouch!
  end

  def check_for_source_changes( local_dir, remote_dir, type='wiki' )
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
    Dir[ '*.asc' ].each do |asc_file|
      target_file_full_path = File.expand_path( File.join( remote_dir, asc_file.chomp( '.asc' ) + '.html' ) )
      source_file_full_path = File.expand_path(asc_file)
      # Skip empty files.
      next if not File.size?( source_file_full_path )
      if not File.exists?( target_file_full_path )  then
        vputs ''
        vputs "Building missing file:  '#{ source_file_full_path }'"
        vputs " ...             into:  '#{ target_file_full_path }'"
        process( local_dir, source_file_full_path, target_file_full_path, type )
        generate_sitemap( File.dirname( target_file_full_path ), local_dir, source_file_full_path, type )
        next
      end
      source_time=File.stat( source_file_full_path ).mtime
      target_time=File.stat( target_file_full_path ).mtime
      if not source_time == target_time then
        target_path=File.join( remote_dir, File.dirname( asc_file ) )
        vputs ''
        vputs "Building unsynced timestamps:  '#{ source_file_full_path }'"
        vputs " ...                    with:  '#{ target_file_full_path }'"
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

def compile( source_file_full_path, target_file_full_path, type='wiki' )
  string = file_read( source_file_full_path )
  @o = Markup.new
  start_time = Time.now

#puts string

  string = @o.compile_main( string, source_file_full_path, target_file_full_path )

#puts string

  create_file( target_file_full_path, string )
  vputs "Compiled in #{ Time.now - start_time } seconds."
end


$VERBOSE = true
# TODO:  Check for an environment variable like $TEMP and use that instead!
#        I see nothing in ENV which I can use.  =/
#        That's because I don't actually have anything set in my shell.  Strange.
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
