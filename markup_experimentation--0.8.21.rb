
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

      # TODO:  If not defined, or if not a regex..
      if right_rx == nil
        then right_rx = left_rx
      end
  
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
      punctuation_start=%r{#{punctuation_start}?}
        
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
      punctuation_end=%r{#{punctuation_end}?}
  
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

  def section_arrays( string )
    rx=%r{(^=+)()()(.*?)()()(=+$)}
    # returns two arrays:  nonhtml, html (nomatch, match)
    return match_new( string, rx, false )
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
        if nonhtml_append.count != html_append.count then puts "markup error:  unbalanced element count" end
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

  def markup_emphasis( string )
    return markup( string, %r{\/}, %r{\/}, '<em>', '</em>' )
  end

  # TODO:  Is there an elegant way for me to just iterate through all methods of a certain name?  markup_* ?
  def markup_everything( string )
    return (
      markup_underline(
      markup_emphasis(
      markup_strong (
        string
      )))
    )
  end

  def sections( string )
    string = "====Testing testing one two three"
    rx = %r{(=+)}
    puts string.match( rx ).to_s.length
    # => 4
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

  # This is now showing an issue with the punctuation rx or the main rx.
  def test_markup_emphasis3()
    assert_equal(
      '<em>usr/bin</em>',
      @o.markup_emphasis( '/usr/bin/' ),
    )
  end

  def test_markup_emphasis4()
# When the above is fixed, try this.
skip
    assert_equal(
      '<em>emp<html>/no</html>hasis</em>',
      @o.markup_emphasis( '/emp<html>/no</html>hasis/' ),
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
      @o.markup_strong( @o.markup_underline( '_*underlined*_ *strong*' ) ),
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

end

__END__

- How do I make my failures easier to read?  It's ugly being all on one line like that.


require File.join(Dir.pwd, 'rb/lib/lib_misc.rb')
require File.join(Dir.pwd, 'rb/lib/lib_files.rb')
file_read(File.join(Dir.pwd, 'source/wiki/compiled-website-demo.asc'))
