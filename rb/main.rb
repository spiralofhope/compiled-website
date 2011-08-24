#!/bin/env ruby

=begin
Implement an exception list for not_in_html() / split_string_html(), so that things like automatic linking will work within <em>

- manual html tables end up with a <pre> line above them..  =/
- Oh!  I could have #!/bin/foo also be detected by my scripting, to use the correct syntax highlighting!
- change the sh syntax highlighting to colour words which are the first on the line and start with \ (maybe pink, like internals?)
- make an accesskey to switch from the live website to the local one.
- Create a "summary" concept, so that one page can refer to another page and get that other page's summary.
=end

# --
# USER CONFIGURATION
# --

# For header and footer customization, hack on /rb/header_and_footer.rb

# Uncomment to give more feedback at the console.
$VERBOSE = true
# TODO:  I have an issue I still need to work out, where the code is outrageously slow because of a complex regex.  Setting this to false will use a simple variation.
#$slow = true..

# TODO:  Check for an environment variable like $TEMP in ENV and use that instead!
#        I don't actually have anything set in my shell.  Strange.  FIXME.
# TODO:  Hardening.  All of these things must exist and be writable!
pid_file = File.join( '', 'tmp', 'compile_child_pid' )
local_wiki  = File.join( File.dirname( __FILE__ ), '..', '..', 'src', 'w' )
local_blog  = File.join( File.dirname( __FILE__ ), '..', '..', 'src', 'b' )
remote_wiki = File.join( File.dirname( __FILE__ ), '..', '..', 'live' )
remote_blog = File.join( File.dirname( __FILE__ ), '..', '..', 'live', 'b' )

# --

require File.join( File.dirname( __FILE__ ), 'header_and_footer.rb' )
require File.join( File.dirname( __FILE__ ), 'lib', 'lib_common.rb' )
require File.join( File.dirname( __FILE__ ), 'lib', 'lib_main.rb' )
require File.join( File.dirname( __FILE__ ), 'tests', 'tc_common.rb' )
require File.join( File.dirname( __FILE__ ), 'tests', 'tc_main.rb' )


# TODO:  Sanity-checking / first-run stuff.
# md_directory( local_wiki )
# md_directory( local_blog )
# md_directory( remote_wiki )
# md_directory( remote_blog )



class Markup

  def rx_html()
    # Regex thanks to
    #   http://www.regular-expressions.info/brackets.html
    #   Originally:  <([A-Z][A-Z0-9]*)\b[^>]*>.*?</\1>
    return %r{
      <                       (?# <html> )
      ([A-Za-z][a-zA-Z0-9]*)  (?# Valid html begins with a letter, then can a combination of letters and numbers. )
      \b                      (?# Word boundary, to support <foo bar="quux"> -type syntax. )
      [^>]*                   (?# This doesn't feel quite right. Technically the > character is legal within tags.  I think it works as expected/desired though. TODO:  Test case. )
      >
      .*?                     (?# Anything:  .*  can be between the <html> and </html>, but don't be greedy:  ?  )
      <                       (?# </html> where 'html' must match the earlier <html>. )
        /
        \1
      >
    }mx
  end

  def split_string_html( string )
    # Like gpartition, except instead of a non-match returning [ (string), '', '' ] it returns [ (string) ]
    # The code or test code needs to be altered to use that instead.. ugh.
    #return string.gpartition2( rx_html() )
    return string.gpartition( rx_html() )
  end
  # Attempting a replacement
  #def split_string_html( string )
    #match_array = [ %r{^<}, %r{^<.*>$} ]
    #return line_partition(
                            #string,
                            #match_array,
                            #'omit',
                            #'omit'
                          #)
  #end


  #def not_in_html( string, *splat )
    #array = split_string_html( string )
    #array.each_index { |i|
      #next if i.odd?
      ## I append a '' to ensure an odd length array.
      ## No need to process that.
      #break if i+1 == array.length and array[i] == ''
      #array[i] = yield( array[i], splat )
    #}
    #return array
  #end

  def not_in_html(
                    string,
                    iterations=1,
                    *splat
                  )
    string = split_string_html( string )
    string = string.each_index { |i|
      next if i.odd?
      # I append a '' to ensure an odd length string.
      # No need to process that.
      if i+1 >= string.length and string[i] == '' then
        return string.join
        #p string, string.class
        #return string.join if string.class == array
        #return string      if string.class == string
      end

      previous = string[i]
      string[i] = yield( string[i], splat )
      u = 1
      until string[i] == previous or u >= iterations
        previous = string[i]
        string[i] = yield( string[i], splat )
        u += 1
      end
    }
    #p string if string == nil
    # I'm not sure if I should omit this and have the user .join, to give more flexibility.
    return string.join
  end # def not_in_html(

  def punctuation_rx(
                      rx_left,
                      rx_right
                    )
    # This would need to be reworked if it should match across lines.  But I don't think it should!
    # TODO:  Match across [ and ] ?
    left=(%r{
      ^       (?# Line left)
      |\      (?# Space)
    }x)
    left=(%r{
       #{ left }
      |#{ left } '
      |#{ left } "
      |#{ left } \(
      |#{ left } --
    }x)
    
    right=(%r{
      $     (?# Line right)
      |\    (?# Space)
    }x)
    right=(%r{
            #{ right }
      |'    #{ right }
      |"    #{ right }
      |\)   #{ right }
      |--   #{ right }
      (?# Additional things can be found on the right )
      |\.   #{ right }
      |,    #{ right }
      |!    #{ right }
      |:    #{ right }
      |;    #{ right }
      |\?   #{ right }
    }x)
    right=(%r{
            #{ right }
      |s    #{ right }
      |es   #{ right }
      |ed   #{ right }
    }x)

    return %r{
      (#{ left })
      (#{ rx_left })
      (.*?)
      (#{ rx_right })
      (#{ right})
    }x
  end

  def punctuation_rx_nospaces(
                                rx_left,
                                rx_right
                              )
    # This would need to be reworked if it should match across lines.  But I don't think it should!
    # TODO:  Match across [ and ] ?
    left=(%r{
      ^       (?# Line left)
      |\      (?# Space)
    }x)
    left=(%r{
       #{ left }
      |#{ left } '
      |#{ left } "
      |#{ left } \(
      |#{ left } --
    }x)
    
    right=(%r{
      $     (?# Line right)
      |\    (?# Space)
    }x)
    right=(%r{
            #{ right }
      |'    #{ right }
      |"    #{ right }
      |\)   #{ right }
      |--   #{ right }
      (?# Additional things can be found on the right )
      |\.   #{ right }
      |,    #{ right }
      |!    #{ right }
      |:    #{ right }
      |;    #{ right }
      |\?   #{ right }
    }x)
    right=(%r{
            #{ right }
      |s    #{ right }
      |es   #{ right }
      |ed   #{ right }
    }x)

    return %r{
      (#{ left })
      (#{ rx_left })
      ([^ ].*?[^ ])
      (#{ rx_right })
      (#{ right})
    }x
  end

  # This is a part of the $slow issue I've been having.  This needs to be investigated.
  def punctuation_rx_single( rx )
      left=(%r{
        ^       (?# Line start)
        |\      (?# Space)
      }x)
      left=(%r{
         #{ left }
        |#{ left } '
        |#{ left } "
        |#{ left } \(
        |#{ left } --
      }x)
        
      right=(%r{
        $     (?# Line end)
        |\    (?# Space)
      }x)
      right=(%r{
              #{ right }
        |\.   #{ right }
        |,    #{ right }
        |!    #{ right }
        |:    #{ right }
        |;    #{ right }
        |\?   #{ right }
        |--   #{ right }
        |'    #{ right }
        |"    #{ right }
      }x)
      right=(%r{
              #{ right }
        |s    #{ right }
        |es   #{ right }
        |ed   #{ right }
      }x)

      return %r{
        (#{ left })
        (#{ rx })
        (#{ right })
      }mx
  end
  
  def markup(
              string,
              left_rx,
              right_rx,
              left_replace,
              right_replace
            )
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
  # maybe some kind of exec() and one of:
  # Array.new.public_methods
  # Array.superclass.public_methods
  def markup_everything( string )
    return (
      # Items lower down are performed first.
      # `truetype`
      markup_truetype(
      # _underline_
      markup_underline(
      # /emphasis/
      markup_emphasis(
      # *strong*
      markup_strong(
      # **big** - lower down, so it's matched before *strong*
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
        array[i].concat( title )
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
        array[i].concat( title )
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
        array[-1].concat( '</div>' )
      end
    end

    return array
  end # def sections( string )

  def paragraphs( string )
    string = not_in_html( string ) { |string|
      # rx = Two or more consecutive \n
      rx = %r{ (\n+{2}) }x
      string.match( rx )
      if $~ != nil then
        length = $~[1].length
        br = "<br />\n" * ( length - 2 )
        string.gsub!( $~[0], "</p>\n#{ br }<p>" )
      end
      string
    }
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
      string.sub!( rx, '\1<a href="\3\4\5\6">\3\4\5\6</a>\7\8' )
      # Without http://
      #string.sub!( rx, '\1<a href="\3\4\5\6">\4\5\6</a>\7\8' )
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

  def links_numbered(
                      string,
                      before,
                      after,
                      inside_before,
                      inside_after,
                      counter
                    )
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

  def links_automatic_files_array( source_file_full_path )
    files_array = Dir[ File.dirname( source_file_full_path ) + '/*.asc' ]
    files_array.delete_if { |x|
      (
        # The current source file is not a valid link target.
        x == source_file_full_path \
      or
        # Only process files.
        # TODO:  Write a test case for this.
        File.file?( x ) != true
      )
    }
    return files_array.sort
  end

  def links_automatic_file_rx( file )
    # '/foo/bar/one-two-three.asc' => [ 'one', 'two', 'three' ]
    basename = File.basename( file, '.asc' ).split( %r{-} )
    #
    # [ 'one', 'two', 'three' ] => %r{ one[-| ]two[-| ]three }
    # This allows matching things like 'compiled website' or 'compiled-website'.
    rx = %r{ #{ basename[0] } }ix
    basename.each_index { |i|
      next if i == 0
      rx = %r{ #{ rx }[-|\ ]#{ basename[i] } }ix
    }
    #
    # Now I need to have a beginning and end to my regular expression, so I don't match inside of other words.
    rx = punctuation_rx( rx, %r{} )
    #
    return rx
  end

  def links_automatic(
                        string,
                        source_file_full_path
                      )

    files_array = links_automatic_files_array( source_file_full_path )

    return not_in_html( string ) { |string|
      files_array.each{ |file|
        file = File.basename( file, '.asc' )
        string.sub!(
          links_automatic_file_rx( file ),
          '\1<a href="' + file + '.html">\2</a>\3\4\5',
        )
      }
      string
    }

  end

  # Local links to new pages, like:  [[link name]] => 'link-name.asc'
  def links_local_new(
                        string,
                        source_file_full_path
                      )
    rx = punctuation_rx_nospaces( %r{\[{2}}, %r{\]{2}} )
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
        string.sub!( rx, '\1\3\5\6' )
      else
        # [[file]] is legitimately new.
        # Turn this into a link to create the file.
        string.sub!( rx, '\1' + '<a class="new" href="file://' + new_source_file_full_path + '">\3</a>' + '\5\6' )
        # Make a blank file so that I can link to an actually-existing file to summon my editor.
        if not File.exists?( new_source_file_full_path ) then
          create_file( new_source_file_full_path )
        end
      end # File.exist?( new_source_file_full_path ) and File.size( new_source_file_full_path ) > 0 then
    end # string.match( rx ) == nil do
    return string
  end

  # TODO:  Add another flag which will not merge multiple matched lines together into one array-element.
# FIXME:  This isn't returning an odd number of elements!
=begin
  def split_string_by_line(
      string,
      rx,
      # one\n\ntwo becomes one\ntwo
      merge_items_separated_by_single_spaces=true,
      lstrip=true
    )
    if not string.match( rx ) then
      return [ string ]
    end

    result = [ '' ]
    previous_line_matched = false
    matchedtwice = false
    string.each_line{ |line|
# TODO:  Build the html skipping in right here.
      if line.match( rx ) then
        result << '' if previous_line_matched == false
        line.lstrip! if lstrip == true
        result[-1].concat( line )
        previous_line_matched = true
      else # this line doesn't match.
        if merge_items_separated_by_single_spaces == true  and
                                             line == "\n"  and
                                          previous_line_matched == true  and  # the previous line was a match
                                     matchedtwice == false then # the previous line was not a "match" with \n
          # not adding \n
          # allow a consecutive match to append.
          previous_line_matched = true
          # don't do this for every consecutive \n, just one.
          matchedtwice = true
        else
          result << '' if previous_line_matched == true
          if merge_items_separated_by_single_spaces == true and
                                       matchedtwice == true then
            result[-1].concat( "\n" )
            matchedtwice = false
          end
          result[-1].concat( line )
          previous_line_matched = false
          matchedtwice = false
        end
      end
    }
    return result
  end
=end






=begin
  def split_string_by_line(
      # Given a string.
      string,
      # Given a regular expression.
      rx
    )
    if not string.match( rx ) then
      return [ string ]
    end
    result = [ '' ]

    # Per-line.
    # TODO:  Re-add all the removed \n
    array = string.split( "\n", -1 )
    matched_previously = false
    array.each_index{ |i|
      # Even numbered elements do not match.
      # Odd numbered elements match.
      # The element boundery is the change from match to not match, e.g.:  [ 'nomatch1', (match), 'nomatch2', (match2) ]
      if array[i].match( rx ) == nil then
        if matched_previously == false then
          result[-1].concat( array[i] ).concat( "\n" )
        else
          result << array[i].concat( "\n" )
        end
        matched_previously = false
      else # matched
        if matched_previously == true then
          result[-1].concat( array[i]).concat( "\n" )
        else
          result << array[i].concat( "\n" )
        end
        matched_previously = true
      end
    }
    # Return an array.
    # The array will have odd-numbered elements.
    p 'eek!' if result.size.even?
    result[-1].chomp!

# Now we need to go through matches
# And make sure that HTML blocks aren't within them.
result.each_index{ |i|
  next if i.even?
  result[i] = split_string_html( result[i] )
}
result.flatten!
# remove consecutive blank spaces
result_element_killer = Array.new
result.each_index{ |i|
  if result[i] == ''
    if result[i-1] == ''
      result_element_killer << i
      result_element_killer << i-1
    end
  end
}
result_element_killer.each{ |i|
  result.delete_at(i)
}

    return result
  end
=end

# TODO:  Additional functionality existed in the previous incarnations, they need to be re-added?  What about tests?  (the last two parameters)
  def split_string_by_line(
                            # Given a string.
                            string,
                            # Given a regular expression.
                            rx,
                            # one\n\ntwo becomes one\ntwo
                            merge_items_separated_by_single_spaces=true,
                            # (to describe)
                            lstrip=true
                          )
    if not string.match( rx ) then
      return [ string ]
    end

    result = [ '' ]
    # Per-line.
    # TODO:  Re-add all the removed \n
    array = string.split( "\n", -1 )
    matched_previously = false
    array.each_index{ |i|
      # Even numbered elements do not match.
      # Odd numbered elements match.
      # The element boundery is the change from match to not match, e.g.:  [ 'nomatch1', (match), 'nomatch2', (match2) ]
      if array[i].match( rx ) == nil then
        if matched_previously == false then
          result[-1].concat( array[i] ).concat( "\n" )
        else
          result << array[i].concat( "\n" )
        end
        matched_previously = false
      else # matched
        if matched_previously == true then
          result[-1].concat( array[i] ).concat( "\n" )
        else
          result << array[i].concat( "\n" )
        end
        matched_previously = true
      end
    }
    # Return an array.
    # The array is supposed to have odd-numbered elements.
    if result.size.even? then
      puts "\n\nI'm getting an even-sized array!\n--v\n#{result}\n--^\n"
      result << ""
    end
    result[-1].chomp!
    return result
  end

  def split_string_by_line_and_html(
                                      string,
                                      rx
                                    )
    array = split_string_by_line( string, rx )
    array.each_index{ |i|
      next if i.even?
      #array[i] = array[i].( rx_html() )
    }
    return array.flatten
  end


      # Optionally strip leading spaces.
#      lstrip=true













# Modifications:
# (match1)\n(match2)   becomes [ '', (match1)(match2) ]
# (match1)\n\n(match2) becomes [ '', (match1), "\n", (match2) ]
# A flag to break apart consecutive matches. (match1)(match2) becomes [ '', (match1), '', (match2) ]
=begin
Skip blocks of html, when html begins at the start of the line.
This should be a separate method.  It's very complex..

- Be sure to properly match html:
<html>
one
</html>     <- this "html" needs to match the earlier "html"

- Deal with nested html of different sorts.
<html>
<foo>
one
</foo>
two         <- this is included in the full "html" block.
</html>

- Deal with nested HTML of the same sort.  Somehow.
<html>
<html>
one
</html>     <- don't allow this to prematurely close the html block.
two         <- this is included in the full "html" block.
</html>

=end

  def lists_arrays( string )
    result = split_string_by_line( string, %r{^\ *[-|\#]+\ +.+?$}, true )
    result.delete_at( -1 ) if result.length > 1 and result[-1] == ''
    return result
  end

  def xx_paragraphs( string )
    string = not_in_html( string ) { |string|
      # rx = Two or more consecutive \n
      rx = %r{ (\n+{2}) }x
      string.match( rx )
      if $~ != nil then
        length = $~[1].length
        br = "<br />\n" * ( length - 2 )
        string.gsub!( $~[0], "</p>\n#{ br }<p>" )
      end
      string
    }
    return '<p>' + string.join + '</p>'
  end

  def split_string_sections( string )
    rx = %r{^=+\ .*?\ =+$}
    result = split_string_by_line( string, rx, false )
    result.delete_at( -1 ) if result.length > 1 and result[-1] == ''
    return result
  end

  def lists_initial_increase(
                              two,
                              string
                            )
    close_tally = Array.new
    if    two[0] == '-' then
      c = 'u'
    elsif two[0] == '#' then
      c = 'o'
    end
    if two.length == 1 then
      open = "<#{ c }l>\n<li>"
      # </ul> or </ol>
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

  def lists_increase(
                      two,
                      string,
                      delta,
                      close_tally
                    )
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
    rx = %r{^(\ *)([-|\#]+)(\ +)(.+)$}
    array = lists_arrays( string )

    array.each_index { |i|
      next if i.even?
      current_list = array[i].split( "\n" )
      close_tally = Array.new
      delta = 0
      previous_length = 0
      current_list.each_index { |j|
        current_list[j].match( rx )
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
          current_list[-1].concat( '</li>' )
          close_tally.each { |e|
            current_list[-1] = current_list[-1] + e
          }
        end
        previous_length = $~[2].length
      } # j (a particular list)
      array[i] = current_list.join( "\n" )
    } # i (the array of lists)
    return array.join
  end

  def blocks_array( string )
    result = split_string_by_line( string, %r{^\ .*$}, true, lstrip=false )
    result.delete_at( -1 ) if result.length > 1 and result[-1] == ''
    return result
  end

  def delete_first_line( string )
    return string.split("\n")[1..-1].join("\n")
  end
  # TODO:  Make universal.. grab any number or ranges of lines.
  def get_line(
                string,
                line
              )
    # This starts counting from one.  Because that's how humans count.
    return string.split("\n")[line-1]
  end
  def blocks( string )
    string = blocks_array( string )
    string.each_index{ |i|
      next if i.even?
      # TODO:  Determine the type of code, and set up the syntax highlighting brush appropriately.
      #        I can peek in and see if I have some kind of custom string starting it off.  Neato!
      string[i] = string[i].unindent
      if string[i][0..3] == '<pre' then
        before = ''
      # FIXME:  This is ugly and not reusable.
      # I should be using some regex magic.
      # FIXME:  Combine rb\n and rb;
      elsif string[i][0..2] == "rb\n" then
        before = "<pre class='brush: #{ get_line( string[i], 1 ) }'>"
        string[i] = delete_first_line( string[i] )
      elsif string[i][0..2] == "rb;" then
        before = "<pre class='brush: #{ get_line( string[i], 1 ) }'>"
        string[i] = delete_first_line( string[i] )
      elsif string[i][0..2] == "sh\n" then
        before = "<pre class='brush: #{ get_line( string[i], 1 ) }'>"
        string[i] = delete_first_line( string[i] )
      elsif string[i][0..3] == "lua\n" then
        before = "<pre class='brush: #{ get_line( string[i], 1 ) }'>"
        string[i] = delete_first_line( string[i] )
      else
        before = '<pre>'
      end
      if string[i][-6..-1] == '</pre>' then
        after = ''
      else
        after = '</pre>'
      end
      string[i] = before + string[i] + after
      if string[i+1] != nil and string[i+1][0] != "\n" then string[i].concat( "\n" ) end
    }
    return string.join
  end

  def compile_main(
                    string,
                    source_file_full_path,
                    type='wiki'
                  )
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

      # FIXME:  While blocks are being created properly, all the stuff below is processing within the blocks.
      #         So I suppose everything has to be checked to properly skip past HTML blocks.
      string[i]          = blocks(            string[i] )
      string[i]          = horizontal_rules(  string[i] )
      string[i]          = links_plain(       string[i] )
      string[i]          = links_named(       string[i] )
    
      string[i], counter = links_numbered(    string[i], '', '', '[', ']', counter )
    
      string[i]          = links_local_new(   string[i], source_file_full_path )
      string[i]          = links_automatic(   string[i], source_file_full_path )
    
      string[i]          = markup_everything( string[i] )

# TODO:  This desperately needs to play nice with html.
# I'm sick of having lists appearing in pre blocks.
      string[i]          = lists(             string[i] )
      #string[i] = not_in_html( string[i]                        ) { |i| lists(i)           }.join

      # Changed to properly work with HTML.
      string[i]          = paragraphs(        string[i] )
      #string[i] = not_in_html( string[i] ) { |i| lists(i) }.join
    }
    string = string.join
    return string
  end

end # class Markup

class Main

  # TODO
  # Also make sure that exclusion is in, to build pseudo-privacy.
  def generate_sitemap(
                        target_file_full_path,
                        local_dir,
                        source_file_full_path,
                        type='wiki'
                      )
    return
  end

  def main(
            local_wiki,
            local_blog,
            remote_wiki,
            remote_blog,
            pid_file
          )
    def process( local_dir, source_file_full_path, target_file_full_path, type='wiki' )
      compile(        source_file_full_path, target_file_full_path, type )
      timestamp_sync( source_file_full_path, target_file_full_path )
      # TODO:  (Optionally) Re-compile all files in that same source directory, to ensure that automatic linking is re-applied to include this new file.  Ouch!
    end

    def check_for_source_changes(
                                  local_dir,
                                  remote_dir,
                                  type='wiki'
                                )
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
      # This was '**/*.asc' but I'm not going to look into subdirectories any more.  A "flat" website is better for SEO.
      Dir[ '*.asc' ].each do |asc_file|
        target_file_full_path = File.expand_path( File.join( remote_dir, asc_file.chomp( '.asc' ) + '.html' ) )
        # FIXME:  This is being naughty and expanding symbolic links.  So I can't make a nice symlink to /c and have alt-e open file:///c/src/w/foo.asc
        source_file_full_path = File.expand_path( asc_file )
        # Skip empty files.
        next if not File.size?( source_file_full_path )
        if not File.exists?( target_file_full_path )  then
          vputs ''
          vputs "Compiling new file '#{ source_file_full_path }'"
          vputs "                => '#{ target_file_full_path }'"
          process( local_dir, source_file_full_path, target_file_full_path, type )
          generate_sitemap( File.dirname( target_file_full_path ), local_dir, source_file_full_path, type )
          next
        end
        source_time=File.stat( source_file_full_path ).mtime
        target_time=File.stat( target_file_full_path ).mtime
        if not source_time == target_time then
          target_path=File.join( remote_dir, File.dirname( asc_file ) )
          vputs ''
          vputs "Syncing timestamps '#{ source_file_full_path }'"
          vputs "                => '#{ target_file_full_path }'"
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

  def compile(
                source_file_full_path,
                target_file_full_path,
                type='wiki'
              )
    string = file_read( source_file_full_path )
    @o = Markup.new
    start_time = Time.now

  #puts string

    string = @o.compile_main(
      string,
      source_file_full_path
    )
    string = @o.header_and_footer(
      string,
      source_file_full_path,
      target_file_full_path,
      type,
    )

  #puts string

    create_file( target_file_full_path, string )
    vputs "Compiled in #{ Time.now - start_time } seconds."
  end

end

Main.new.main(
                local_wiki,
                local_blog,
                remote_wiki,
                remote_blog,
                pid_file,
              )
