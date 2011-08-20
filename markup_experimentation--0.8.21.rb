
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

  def markup( string, rx, left_replace, right_replace )
    # Separate HTML from non-HTML content.
    nonhtml, html = html_arrays( string )
    # For the nonhtml components.
    nonhtml.each_index do |i|
      next if nonhtml[i] == nil
      # Perform markup.
      # TODO:  This would be better as a timer, and not as a counter like this.
      c=0
      until ( nonhtml[i].match( rx ) == nil ) or ( c > 1000 ) do
        c=c+1
        nonhtml[i].sub!( rx, $~[1] + left_replace + $~[3] + right_replace + $~[5] )
      end
      if c > 1000 then puts "ERROR:  markup_underline() received a huge number of matches" end
    end
    return recombine( nonhtml, html ).join
  end

  def markup_underline( string )
    rx = punctuation_rx( %r{_}, %r{_} )
    left_replace = '<u>'
    right_replace = '</u>'
    return markup( string, rx, left_replace, right_replace )
  end

  def markup_strong( string )
    rx = punctuation_rx( %r{\*}, %r{\*} )
    left_replace = '<strong>'
    right_replace = '</strong>'
    return markup( string, rx, left_replace, right_replace )
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

  def test_multiple_markup()
    string = '_underlined_ and *strong*'
    expected = '<u>underlined</u> and <strong>strong</strong>'
    result = @o.markup_underline( string )
    result = @o.markup_strong( string )
    assert_equal(
      expected,
      result,
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
    # Why is nomatch[2] = ''   ?
    assert_equal(
      [ "This is an example document.\n\n", nil, '', "\n\nText in section one.\n\n", nil, "\n\nText in section two.\n" ],
      nomatch,
    )
    # Why is match[3] = nil    ?
    assert_equal(
      [ nil, '= Title One =', nil, nil, '= Title Two =', nil],
      match,
    )
  end

end


__END__


  def markup( string )
    # I'm initially given a string with multiple lines.
    # Determine what parts of that line are processable.  All the already-htmlized parts need to be ignored.
    # TODO:  This 'processable' stuff needs to be relocated to the markup_replacing code.
    # I need to, on-the-fly, avoid processing htmlized parts.
    process_should     = Array.new
    process_should_not = Array.new
    process_should, process_should_not = processable( %r{<.*?>}, %r{</.*?>}, string )
    process_should.each_index do |i|
      next if process_should[i] == nil

      # HACK:  By re-using markup characters and doubling them up, I introduce wacky errors.
      #        So --del-- is in conflict with -em-.  So --foo-- becomes <em>-foo-</em>
      #        FIXME:  Find some better workaround for this.  Markup shouldn't be order-dependent.
      # strikethrough
      process_should[i] = markup_replacing( process_should[i], %r{--}, 'del' )
      # subscript
      process_should[i] = markup_replacing( process_should[i], %r{__}, 'sub' )
      # big
      process_should[i] = markup_replacing( process_should[i], %r{\*\*}, 'big' )
      # bold emphasis
      # emphasis bold
      # -*string*- and *-string-*
      # process_should[i] = markup_replacing_asymmetrical( process_should[i], %r{\*\*}, 'big' )
      # should I bother with big+bold, or big+emphasis, or big+bold+emphasis?

      # underline
      process_should[i] = markup_replacing( process_should[i], %r{_}, 'u' )
      # string / bold
      process_should[i] = markup_replacing( process_should[i], %r{\*}, 'strong' )
      # emphasis
      process_should[i] = markup_replacing( process_should[i], %r{-}, 'em' )
      process_should[i] = markup_replacing( process_should[i], %r{\/}, 'em' )
      # superscript
      process_should[i] = markup_replacing( process_should[i], %r{\^}, 'sup' )
      # truetype
      process_should[i] = markup_replacing( process_should[i], %r{`}, 'tt' )
    end
    return combine_arrays( process_should, process_should_not ).join
  end

end

class Test_Markup < MiniTest::Unit::TestCase
  def setup()
    @o = Markup.new
    #(
    #@document = <<-heredoc.unindent
        #ex.
        #_underlined_
        #<nowiki>
        #_underlined_
        #</nowiki>
        #_underlined_
    #heredoc
    #)
  end
  
  def test_strong()
      assert_equal(
        ( <<-heredoc.unindent
          <strong>strong</strong>
        heredoc
        ),
        @o.markup( <<-heredoc.unindent
          *strong*
        heredoc
        ),
      )
  end
  
  def test_big()
      assert_equal(
        ( <<-heredoc.unindent
          <big>big</big>
        heredoc
        ),
        @o.markup( <<-heredoc.unindent
          **big**
        heredoc
        ),
      )
  end
  
  def test_em()
      assert_equal(
        ( <<-heredoc.unindent
          <em>emphasis</em>
          <em>emphasis</em>
        heredoc
        ),
        @o.markup( <<-heredoc.unindent
          /emphasis/
          -emphasis-
        heredoc
        ),
      )
  end
  
  def test_del()
      assert_equal(
        ( <<-heredoc.unindent
          <del>del</del>
        heredoc
        ),
        @o.markup( <<-heredoc.unindent
          --del--
        heredoc
        ),
      )
  end
  
  def test_sup()
      assert_equal(
        ( <<-heredoc.unindent
          <sup>superscript</sup>
        heredoc
        ),
        @o.markup( <<-heredoc.unindent
          ^superscript^
        heredoc
        ),
      )
  end
  
  def test_sub()
      assert_equal(
        ( <<-heredoc.unindent
          <sub>subscript</sub>
        heredoc
        ),
        @o.markup( <<-heredoc.unindent
          __subscript__
        heredoc
        ),
      )
  end
  
  def test_tt()
      assert_equal(
        ( <<-heredoc.unindent
          <tt>truetype</tt>
        heredoc
        ),
        @o.markup( <<-heredoc.unindent
          `truetype`
        heredoc
        ),
      )
  end

  def test_u()
    assert_equal(
      ( <<-heredoc.unindent
        <u>underlined</u>
      heredoc
      ),
      @o.markup( <<-heredoc.unindent
        _underlined_
      heredoc
      ),
    )
  end

  def test_html_block()
    assert_equal(
      ( <<-heredoc.unindent
        <u>a</u><>_b_</>
      heredoc
      ),
      @o.markup( <<-heredoc.unindent
        _a_<>_b_</>
      heredoc
      ),
    )
  end

  def test_u2()
    assert_equal(
      ( <<-heredoc.unindent
        <>_underlined_</>  
          <u>underlined</u>  
      heredoc
      ),
      @o.markup( <<-heredoc.unindent
        <>_underlined_</>  
          _underlined_  
      heredoc
      ),
    )
  end

  def test_u_wrapped1()
    assert_equal(
      ( <<-heredoc.unindent
        <u>underlined
        wraparound</u>
      heredoc
      ),
      @o.markup( <<-heredoc.unindent
        _underlined
        wraparound_
      heredoc
      ),
    )
  end

  def test_u_wrapped2()
    assert_equal(
      ( <<-heredoc.unindent
        <u>underlined
        also
        wraparound</u>
      heredoc
      ),
      @o.markup( <<-heredoc.unindent
        _underlined
        also
        wraparound_
      heredoc
      ),
    )
  end

=begin
  def test_double_syntax()
    assert_equal(
      ( <<-heredoc.unindent
        <em><strong>bold emphasis</strong></em>
      heredoc
      ),
      @o.markup( <<-heredoc.unindent
        -*bold emphasis*-
      heredoc
      ),
    )
  end
=end

  def test_multiple_markup()
    assert_equal(
      ( <<-heredoc.unindent
        <u>a</u> <u>b</u>
      heredoc
      ),
      @o.markup( <<-heredoc.unindent
        _a_ _b_
      heredoc
      )
    )
  end

  #def test_multiple_markup2()
    ## This demonstrates an issue where
    ##   if I have two markups, the two </close> html tags are then picked up by the emphasis markup code.
    #assert_equal(
      #( <<-heredoc.unindent
        #<strong>a</strong> <u>b</u>
      #heredoc
      #),
      #@o.markup( <<-heredoc.unindent
        #*a* _b_
      #heredoc
      #)
    #)
  #end

end

__END__

- How do I make my failures easier to read?  It's ugly being all on one line like that.


require File.join(Dir.pwd, 'rb/lib/lib_misc.rb')
require File.join(Dir.pwd, 'rb/lib/lib_files.rb')
file_read(File.join(Dir.pwd, 'source/wiki/compiled-website-demo.asc'))
