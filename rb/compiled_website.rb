=begin
To do:

- Multiple line breaks creating <p>
-- The old way is nasty and must be redone.
- Sections counting and incrementing a CSS counter (for my funky sidebar or colour changes)
- Linking plain URLs. http://example.com  ->  <a href="http://example.com">example.com</a>
- Linking markup (named URLs) [http://example.com example] -> <a href="http://example.com">example</a>
- Numbered links [http://example.com] -> <a href="http://example.com">[1]</a>
- Auto-linking.
- Prepending a header, appending a footer.
- HTML Tidy
- The background pid stuff.


- "proper" footnoting/endnoting
-- The user creates [1] markers, manually incrementing the number.
-- The user creates matching [1] markers at the bottom of the section or the end of the page.
-- The system detects if the user put them at the bottom or end.
-- The system picks up all of the [1] markers and re-numbers them so they are in-order.  The foot/endnotes are also picked up and sorted the same way.
-- This allows a person to go [2] [1] [4] [3] and the system will freely correct everything.


Allow only one document-links for each header-section.  For each section maintain an array of already-existing links.  Check for each addition and don't add duplicates.

=end


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
    re = Regexp.new( '^\s{0,' + first_line_ws.length.to_s + '}' )

    lines.collect { |line| line.sub(re, "") }.join
  end
end


class Markup

  # Using a regular expression, break a string into two arrays.
  #   One matching the regular expression
  #   , the other not matching the regular expression.
  #   Keep the two arrays "aligned" by padding elements with nils.
  #   Where there is content in array1[n], there is a nil in array2[n] and vice-versa.
  #   Optionally keep the start/end of the match included in the rx.
  def match( string, rx, rx_include_matched_characters_bool )
    # rx expects three matches, like:  (rx1)(rx2)(rx3)
    # TODO:  Sanity-check the rx somehow?
    rx_match = Array.new
    rx_nomatch = Array.new
    rx_match = [ string ]
    i=0
    until rx_match[-1].match( rx ) == nil or i > 100 do
      i+=1
      rx_match.delete_at(-1)
      rx_match   << $`
      rx_match   << nil
      rx_match   << $'
      rx_nomatch << nil
      # ( $~[3] or "" ) is specifically for section matching using false.
      if rx_include_matched_characters_bool == true then
        rx_nomatch << ( $~[1] + $~[2] + ( $~[3] or "" ) )
      else
        rx_nomatch << (         $~[2]         )
      end
      if i > 100 then puts "## ERROR in match1() - Long loop in regex usage.  Did you pass a bad rx?" end
    end
    return rx_match, rx_nomatch
  end

  def match_new( string,       # "This has <html>some html</html> in it."
                 match_rx,     # Seven elements.  e.g. HTML is (<)(.*?)(>)(.*?)(</)(.*?)(>)
                 replace_array #                               (a)( b )(c)(.*?)(d )( e )(f)
                               #                            .. which is [ a, b, c, d, e, f ]
              )
    match   = [ nil    ]
    nomatch = [ string ]
    #
    # TODO:  Sanity-checking.
    if replace_array == false then
      replace_array = [ nil, nil, nil, nil, nil, nil ]
    end
    # Count starting from one, dammit.
    replace_array.insert(0, nil)
    # Pad a nil in the middle to make the replace_array number of elements the same as the $~ matches.  3 before, 1 match, 3 after ( 7 ).
    replace_array.insert(4, nil)
    #
    firstpass = true
    until nomatch[-1].match( match_rx ) == nil
      # If this is my first pass, empty the array.
      if firstpass == true then
        firstpass = false
        nomatch = Array.new
        match = Array.new
      else
        nomatch[-1] = ''
      end
      # Before the match.
      nomatch << $`
      match   << nil
      # The match.
      nomatch << nil
      match   << ""
      (1..7).each do |i|
        match[-1] += if replace_array[i] == nil then $~[i] else replace_array[i] end
      end      
      # After the match.  To be re-examined on the next pass.
      nomatch << $'
      match   << nil
    end
    return nomatch, match
  end

  # Taking the contents of array1, replace any nils with contents from the same position in array2.
  def recombine( array1, array2 )
    array1.each_index do |i|
      if array1[i] == nil then
        if array2[i] == nil then
          puts "ERROR - recombine"
        end
        array1[i] =  array2[i]
      end
    end
    return array1
  end

  def punctuation_rx( left_rx, right_rx )

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
      }mx
  end
  
  def html_arrays( string )
    html_exclusion_rx = %r{
      (<)(.*?)(>)
      (.*?)
      (</)(.*?)(>)
    }mx
    # returns two arrays:  nonhtml, html (nomatch, match)
    return match_new( string, html_exclusion_rx, false )
  end

  def markup( string, left_rx, right_rx, left_replace, right_replace )
    rx = punctuation_rx( left_rx, right_rx )
    # Separate HTML from non-HTML content.
    nonhtml, html = html_arrays( string )
    # For the nonhtml components.
    nonhtml.each_index do |i|
      next if nonhtml[i] == nil
      if nonhtml[i].match( rx ) != nil then
        nonhtml[i].sub!( rx, $~[1] + left_replace + $~[3] + right_replace + $~[5] )
        # Now that a search-and-replace has been performed, I re-split from that element.
        # TODO:  I should be able to do this without these intermediate variables, but how?
        nonhtml_append, html_append = html_arrays( nonhtml[i] )
# if nonhtml_append.count != html_append.count then puts "markup error:  unbalanced element count" end
# if html[i] != nil then puts "markup error:  html[i] has a non-nil in it" end
        nonhtml[i] = nonhtml_append
           html[i] = html_append    # This is stomping over it, but that ought to be ok.. it's nil.
        nonhtml.flatten!
           html.flatten!
      end
    end
if nonhtml.count != html.count then puts "markup error:  unbalanced element count" end
    return recombine( nonhtml, html ).join
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

  def section_arrays( string )
    rx=%r{(^=+)(\ )()(.*?)()(\ )(=+$)}
    # returns two arrays:  nonhtml, html (nomatch, match)
    return match_new( string, rx, false )
  end

  def sections( string )
    nomatch, match = section_arrays( string )
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

  def lists( section_titles_array, section_contents_array )
    return section_titles_array, section_contents_array
  end

end # class Markup


# http://bfts.rubyforge.org/minitest/
require 'minitest/autorun'
class Test_Markup < MiniTest::Unit::TestCase

  def setup()
    @o = Markup.new
  end

  def test_match_new_splitting()
    string = 'abcdefghijklmnopqrstuvwxyz'
    rx = %r{(not matching this)()()()()()()}
    assert_equal(
      [ string ],
      @o.match_new( string, rx, false )[0], # match
    )
    assert_equal(
      [ nil ],
      @o.match_new( string, rx, false )[1], # nomatch
    )
  end

  def test_match_new_splitting_replacing()
    string = '---ABCoooooABC---'
    rx = %r{(A)(B)(C)(.*?)(A)(B)(C)}
    nomatch, match = @o.match_new( string, rx, false )
    assert_equal(
      [[nil, 'ABCoooooABC', nil ],['---', nil, '---' ]],
      [match, nomatch]
    )

    string = '---AoooooA---'
    rx = %r{(A)()()(.*?)(A)()()}
    nomatch, match = @o.match_new( string, rx, false )
    assert_equal(
      [[nil, 'AoooooA', nil ],['---', nil, '---' ]],
      [match, nomatch]
    )

    string = 'AoooooA---'
    rx = %r{(A)()()(.*?)(A)()()}
    nomatch, match = @o.match_new( string, rx, false )
    assert_equal(
      [[nil, 'AoooooA', nil ],['', nil, '---' ]],
      [match, nomatch]
    )

    string = '---AoooooA'
    rx = %r{()(A)()(.*?)()(A)()}
    nomatch, match = @o.match_new( string, rx, false )
    assert_equal(
      [[nil, 'AoooooA', nil ],['---', nil, '' ]],
      [match, nomatch]
    )

    string = 'AoooooA'
    rx = %r{()()(A)(.*?)()()(A)}
    nomatch, match = @o.match_new( string, rx, false )
    assert_equal(
      [[nil, 'AoooooA', nil ],['', nil, '' ]],
      [match, nomatch]
    )

  end

  def test_html_arrays()
    nonhtml, html = @o.html_arrays( '<></>' )
    assert_equal(
      [ '', nil, '' ],
      nonhtml,
    )
    assert_equal(
      [ nil , '<></>', nil   ],
      html,
    )
    string = '<html>text</html>'
    nonhtml, html = @o.html_arrays( string )
    assert_equal(
      string,
      html[1],
    )

    nonhtml, html = @o.html_arrays( 'This is <html>some example html</html>.' )
    assert_equal(
      [ 'This is ', nil                             , '.' ],
      nonhtml,
    )
    assert_equal(
      [ nil       , '<html>some example html</html>', nil   ],
      html,
    )
  end

  def test_multiple_html()
    string = '<1>2</3><4>5</6>'
    expected_nonhtml = 
    expected_html =    

    assert_equal(
      [ nil, '<1>2</3>', nil, nil, '<4>5</6>', nil ],
      @o.html_arrays( string )[1], # html
    )

    assert_equal(
      [ '' , nil , '' , '', nil, '' ],
      @o.html_arrays( string )[0], # nonhtml
    )

    assert_equal(
      string,
      @o.markup_underline( string ),
    )
  end

  def test_recombine()
    array1 = [ "1", nil, nil, "4" ]
    array2 = [ nil, "2", "3", nil ]
    assert_equal(
      [ "1", "2", "3", "4" ],
      @o.recombine( array1, array2 ),
    )
    array1 = [ nil, "2", "3", nil ]
    array2 = [ "1", nil, nil, "4" ]
    assert_equal(
      [ "1", "2", "3", "4" ],
      @o.recombine( array1, array2 ),
    )
  end

  def test_html_arrays_replacing()
    rx = %r{
      (<)(.*?)(>)
      (.*?)
      (</)(.*?)(>)
    }mx
    string = 'This is <html>some example html</html>.'

    nomatch, match = @o.match_new(
      string,
      rx,
      false,
    )
    assert_equal(
      'This is <html>some example html</html>.',
      @o.recombine( nomatch, match ).join,
    )

    nomatch, match = @o.match_new(
      string,
      rx,
      [ nil, nil, nil, nil, nil, nil ],
    )
    assert_equal(
      'This is <html>some example html</html>.',
      @o.recombine( nomatch, match ).join,
    )
  
    nomatch, match = @o.match_new(
      string,
      rx,
      [ '|', nil, nil, nil, nil, nil ],
    )
    assert_equal(
      'This is |html>some example html</html>.',
      @o.recombine( nomatch, match ).join,
    )

    nomatch, match = @o.match_new(
      string,
      rx,
      [ nil, '|', nil, nil, nil, nil ],
    )
    assert_equal(
      'This is <|>some example html</html>.',
      @o.recombine( nomatch, match ).join,
    )
  
    nomatch, match = @o.match_new(
      string,
      rx,
      [ nil, nil, '|', nil, nil, nil ],
    )
    assert_equal(
      'This is <html|some example html</html>.',
      @o.recombine( nomatch, match ).join,
    )
  
    nomatch, match = @o.match_new(
      string,
      rx,
      [ nil, nil, nil, '|', nil, nil ],
    )
    assert_equal(
      'This is <html>some example html|html>.',
      @o.recombine( nomatch, match ).join,
    )
  
    nomatch, match = @o.match_new(
      string,
      rx,
      [ nil, nil, nil, nil, '|', nil ],
    )
    assert_equal(
      'This is <html>some example html</|>.',
      @o.recombine( nomatch, match ).join,
    )
  
    nomatch, match = @o.match_new(
      string,
      rx,
      [ nil, nil, nil, nil, nil, '|' ],
    )
    assert_equal(
      'This is <html>some example html</html|.',
      @o.recombine( nomatch, match ).join,
    )
  end
  
  def test_markup_underline()
    assert_equal(
      '<u>underlined</u>',
      @o.markup_underline( '_underlined_' ),
    )
  end

  def test_underline_two_words()
    assert_equal(
      '<u>underlined across</u>',
      @o.markup_underline( '_underlined across_' ),
    )
  end

  def test_multiple_markup_underline()
    assert_equal(
      '<u>1</u> <u>2</u>',
      @o.markup_underline( '_1_ _2_' ),
    )
  end

  def test_underline_across_line_breaks()
    string = <<-heredoc.unindent
      _underlined
      across_
    heredoc
    expected = <<-heredoc.unindent
      <u>underlined
      across</u>
    heredoc
    assert_equal(
      expected,
      @o.markup_underline( string ),
    )
  end

  def test_underline_within_html()
    string = '<html>_underline_</html>'
    assert_equal(
      string,
      @o.markup_underline( string ),
    )
  end

  def test_underline_within_html_multiline()
    string = <<-heredoc.unindent
      <html>
      _underline_
      </html>
    heredoc
    assert_equal(
      string,
      @o.markup_underline( string ),
    )
  end

  def test_underline_within_html_multiline_multiples()
    string = <<-heredoc.unindent
      <html>
      _underline_
      </html>
      <html>
      _underline_
      </html>
      <html>_underline_</html>
    heredoc
    assert_equal(
      string,
      @o.markup_underline( string ),
    )
  end

  def test_markup_strong()
    assert_equal(
      '<strong>strong</strong>',
      @o.markup_strong( '*strong*' ),
    )
  end

  def test_markup_emphasis()
    assert_equal(
      '<em>emphasis</em>',
      @o.markup_emphasis( '/emphasis/' ),
    )
  end

  def test_markup_emphasis2()
    assert_equal(
      '<html>/no</html><em>emphasis</em>',
      @o.markup_emphasis( '<html>/no</html>/emphasis/' ),
    )
  end

  def test_markup_emphasis3()
    assert_equal(
      '<em>usr/bin</em>',
      @o.markup_emphasis( '/usr/bin/' ),
    )
  end

  # Markup does not cross HTML bounderies.
  # Because that would be insanity.
  def test_markup_emphasis4()
    string = '<em>emp<html>/no</html>hasis</em>'
    assert_equal(
      string,
      @o.markup_emphasis( string ),
    )
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

  def test_section_arrays_multiple()
    string = <<-heredoc.unindent
      This is an example document.
      
      = Title One =
      
      Text in section one.
      
      = Title Two =
      
      Text in section two.
    heredoc
    nomatch, match = @o.section_arrays( string )
    assert_equal(
      [ "This is an example document.\n\n", nil, '', "\n\nText in section one.\n\n", nil, "\n\nText in section two.\n" ],
      nomatch,
    )
    assert_equal(
      [ nil, '= Title One =', nil, nil, '= Title Two =', nil],
      match,
    )
  end

  def test_sections()
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

  def test_sections_large()
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

  def test_sections_multiple()
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

  def test_sections_increment()
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

  def test_sections_increment_lots()
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

  def test_sections_increment2()
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

  def test_sections_decrement()
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

  def test_sections_decrement_lots()
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

  def test_lists()
    #expected = <<-heredoc.unindent
      #test
      #<ul><li>1</li>
      #</ul>
    #heredoc
    #match, nomatch = @o.sections( <<-heredoc.unindent
      #test
       #- 1
    #heredoc
    #)
    #result = @o.recombine( match, nomatch ).join + "\n"
    #assert_equal(
      #( expected ),
      #( result ),
    #)
  end


end


# ------------------------------------


def create_file( file, file_contents )
  # TODO: This can't create a file if it's in a subdirectory that doesn't exist.  I get a TypeError.  Perhaps I could intelligently create the directory..
  vputs "creating file: " + file
  # TODO: check that I have write access to my current directory.
  # TODO: check for overwriting an existing file.  Also implement an optional flag to overwrite it.
  begin
    File.open(file, 'w+') do |f| # open file for update
      f.print file_contents      # write out the example description
    end                          # file is automatically closed
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
  Dir.chdir(directory)
  # This is a good idea, but it fails if I'm in a symlinked directory..
  # TODO: Recursively check if I'm in a symlinked dir.  =)
#   if Dir.getwd != directory then
#     puts "cd failed.  I'm in\n" + Dir.getwd + "\n.. but you wanted \n" + directory
#     return 1
#   end
end

# used for FileUtils.mkdir_p
require 'fileutils'
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
    Process.kill(0, pid)
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
    pid=File.extname( file )[1..-1].to_i
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
  # NOTE: This code has been copied verbatim.  If you need to edit it, edit the source misc.rb from which it came.
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


# ------------------------------------------

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
    vputs Time.now
  end
end # main




def compile( source_file_full_path, target_file_full_path, type )

  @o = Markup.new
  create_file(
    target_file_full_path,
    @o.markup_everything( file_read( source_file_full_path ) ),
  )

end


$VERBOSE=true
# TODO:  Check for an environment variable like $TEMP and use that instead!
#        I see nothing in ENV which I can use.  =/
pid_file = File.join( '', 'tmp', 'compile_child_pid' )
local_wiki = '/tmp/cw/w'
local_blog = '/tmp/cw/b'
remote_wiki = '/tmp/cw/remote'
remote_blog = remote_wiki

md_directory( local_wiki )
md_directory( local_blog )
md_directory( remote_wiki )
md_directory( remote_blog )

main( local_wiki, local_blog, remote_wiki, remote_blog, pid_file )


__END__

require File.join(Dir.pwd, 'rb/lib/lib_misc.rb')
require File.join(Dir.pwd, 'rb/lib/lib_files.rb')
file_read(File.join(Dir.pwd, 'source/wiki/compiled-website-demo.asc'))
