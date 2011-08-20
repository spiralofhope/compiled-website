
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


# ---------------------------------------


# http://bfts.rubyforge.org/minitest/
require 'minitest/autorun'

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
    if string.match( match_rx ) == nil then
      return [
        [ nil    ], # match
        [ string ], # nomatch
      ]
    end
    # TODO:  Sanity-checking.
    if replace_array == false then
      replace_array = [ nil, nil, nil, nil, nil, nil ]
    end
    match   = [        ]
    nomatch = [ string ]

    until ( nomatch[-1]                   == nil ) or
          ( nomatch[-1].match( match_rx ) == nil )
      # Before the match.
      nomatch << $`
      match   << nil
      # The match.
      nomatch << nil
      match << ""
      # Make the replace_array "line up" with the match data.
      # So the 6-element replace array will align with 7 match items.
      # Starting the numbering at 1, so I add a nil at the start.
      replace_array.insert(0, nil)
      # And a nil in the middle.
      replace_array.insert(3, nil)
      replace_array.each_index do |i|
        replace_array[i] = ( replace_array[i] or $~[i] )
      end
      # Remove that starting nil.
      replace_array.delete_at(0)
      replace_array.each do |i|
        match[-1] << ( i or "" )
      end
      # After the match.
      nomatch << $'
      match   << nil
    end
    # Because I originally inserted the full string into match[], I need to remove it.
    nomatch.delete_at(0)
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
      }x
  end
  
  def html_arrays( string )
    html_exclusion_rx = %r{
      (<)(.*?)(>)
      (.*?)
      (</)(.*?)(>)
    }mx
    # returns two arrays:  nonhtml, html
    return match_new( string, html_exclusion_rx, false )
  end

  def markup_underline( string )
# FIXME FIXME
    rx = punctuation_rx( %r{_}, %r{_} )
    rx = %r{
      (_)
      ()
      ()
      (.*?)
      ()
      ()
      (_)
    }mx
    replace_array = [ '<u>', nil, nil, nil, nil, '</u>' ]
    # Separate HTML from non-HTML content.
    html, nonhtml = html_arrays( string )

#if nonhtml.size == 0 then return
#recombine( html, nonhtml ).join
#end

    # For the nonhtml components.
    nonhtml.each_index do |i|
      next if nonhtml[i] == nil
      # Perform markup.
      a, b = match_new( nonhtml[i], rx, replace_array )
      nonhtml[i] = recombine( a, b ).join
    end

    return recombine( nonhtml, html ).join
  end

end # class Markup

class Test_Markup < MiniTest::Unit::TestCase

  def setup()
    @o = Markup.new
  end

  def test_html_arrays()
    string = <<-heredoc.unindent
      This is <html>some example html</html>.
    heredoc
    expected_nonhtml = [ "This is ", nil                             , ".\n" ]
    expected_html    = [ nil       , "<html>some example html</html>", nil   ]
    nonhtml, html = @o.html_arrays( string )

    assert_equal(
      expected_nonhtml,
      nonhtml,
    )
    assert_equal(
      expected_html,
      html,
    )

  end
  
  def test_markup_underline()
    assert_equal(
      '<u>underlined</u>',
      @o.markup_underline( '_underlined_' ),
    )
  end

  def test_multiple_markup_underline()
    assert_equal(
      '<u>1</u> <u>2</u>',
      @o.markup_underline( '_1_ _2_' ),
    )
  end
  
end

class Test_Markup < MiniTest::Unit::TestCase

  def setup()
    @o = Markup.new
  end
  
  def test_match_keep_rx()
    string = "0<>1</><>2</>"
    rx = %r{(<.*?>)(.*?)(</.*?>)}m
    rx_nomatch, rx_match = @o.match( string, rx, true )
    # Matching the regular expression
    assert_equal(
      nil,
      rx_match[0],
    )
    assert_equal(
      "<>1</>",
      rx_match[1],
    )
    assert_equal(
      nil,
      rx_match[2],
    )
    assert_equal(
      "<>2</>",
      rx_match[3],
    )
    # Not matching the regular expression
    assert_equal(
      "0",
      rx_nomatch[0],
    )
    assert_equal(
      nil,
      rx_nomatch[1],
    )
    assert_equal(
      "",
      rx_nomatch[2],
    )
    assert_equal(
      nil,
      rx_nomatch[3],
    )
  end

  def test_match_nokeep_rx()
    string = "0<>1</><>2</>"
    rx = %r{(<.*?>)(.*?)(</.*?>)}m
    rx_nomatch, rx_match = @o.match( string, rx, false )
    # Matching the regular expression
    assert_equal(
      nil,
      rx_match[0],
    )
    assert_equal(
      "1",
      rx_match[1],
    )
    assert_equal(
      nil,
      rx_match[2],
    )
    assert_equal(
      "2",
      rx_match[3],
    )
    # Not matching the regular expression
    assert_equal(
      "0",
      rx_nomatch[0],
    )
    assert_equal(
      nil,
      rx_nomatch[1],
    )
    assert_equal(
      "",
      rx_nomatch[2],
    )
    assert_equal(
      nil,
      rx_nomatch[3],
    )
  end

  def test_sections()
    string = <<-heredoc.unindent
      This is an example document.
      
      = Title One =
      
      This is section one.
      
      = Title Two =
      
      Section two.
    heredoc
    rx=%r{
      ^
      (=+)
      \       (?# This is here to ensure there is a trailing space.)
      (.+?)
      \       (?# )
       =+
      $
    }mx

    rx_nomatch, rx_match = @o.match( string, rx, false )
    # Matching the regular expression
    assert_equal(
      nil,
      rx_match[0],
    )
    assert_equal(
      "Title One",
      rx_match[1],
    )
    assert_equal(
      nil,
      rx_match[2],
    )
    assert_equal(
      "Title Two",
      rx_match[3],
    )
    assert_equal(
      nil,
      rx_match[4],
    )
    # Not matching the regular expression
    assert_equal(
      "This is an example document.\n\n",
      rx_nomatch[0],
    )
    assert_equal(
      nil,
      rx_nomatch[1],
    )
    assert_equal(
      "\n\nThis is section one.\n\n",
      rx_nomatch[2],
    )
    assert_equal(
      nil,
      rx_nomatch[3],
    )
    assert_equal(
      "\n\nSection two.\n",
      rx_nomatch[4],
    )

    rx_nomatch, rx_match = @o.match( string, rx, true )
    # Matching the regular expression
    assert_equal(
      nil,
      rx_match[0],
    )
    assert_equal(
      "=Title One",
      rx_match[1],
    )
    assert_equal(
      nil,
      rx_match[2],
    )
    assert_equal(
      "=Title Two",
      rx_match[3],
    )
    assert_equal(
      nil,
      rx_match[4],
    )
    # Not matching the regular expression
    assert_equal(
      "This is an example document.\n\n",
      rx_nomatch[0],
    )
    assert_equal(
      nil,
      rx_nomatch[1],
    )
    assert_equal(
      "\n\nThis is section one.\n\n",
      rx_nomatch[2],
    )
    assert_equal(
      nil,
      rx_nomatch[3],
    )
    assert_equal(
      "\n\nSection two.\n",
      rx_nomatch[4],
    )
  end

  def test_basic_markup()
    string = <<-heredoc.unindent
      This is a test *testing hey* I wonder.
    heredoc
    rx = %r{(\*)(.*?)(\*)}
    rx_nomatch, rx_match = @o.match( string, rx, false )
    # Matching the regular expression
    assert_equal(
      nil,
      rx_match[0],
    )
    assert_equal(
      "testing hey",
      rx_match[1],
    )
    assert_equal(
      nil,
      rx_match[2],
    )
    # Not matching the regular expression
    assert_equal(
      "This is a test ",
      rx_nomatch[0],
    )
    assert_equal(
      nil,
      rx_nomatch[1],
    )
    assert_equal(
      " I wonder.\n",
      rx_nomatch[2],
    )

    rx_nomatch, rx_match = @o.match( string, rx, true )
    # Matching the regular expression
    assert_equal(
      nil,
      rx_match[0],
    )
    assert_equal(
      "*testing hey*",
      rx_match[1],
    )
    assert_equal(
      nil,
      rx_match[2],
    )
    # Not matching the regular expression
    assert_equal(
      "This is a test ",
      rx_nomatch[0],
    )
    assert_equal(
      nil,
      rx_nomatch[1],
    )
    assert_equal(
      " I wonder.\n",
      rx_nomatch[2],
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

  #def test_markup()
    #string = "This is *strong* text."
    #assert_equal(
      #"This is <strong>strong</strong> text.",
      #@o.markup( string, false )
    #)
  #end

  #def test_markup2()
    #string = "0<>1</><>2</>"
    #rx = %r{()(<.*?>)(.*?)(</.*?>)()}m
    #rx_nomatch, rx_match = @o.match( string, rx, true )
    ## Matching the regular expression
    #assert_equal(
      #[ nil, nil, "<>1</>", nil, nil, "<>2</>", nil ],
      #[ rx_match[0], rx_match[1], rx_match[2], rx_match[3], rx_match[4], rx_match[5], rx_match[6] ],
    #)
    ## Not matching the regular expression
    #assert_equal(
      #[ "0", "", nil, "", "", "", nil, "" ],
      #[ rx_nomatch[0], rx_nomatch[1], rx_nomatch[2], rx_nomatch[3], rx_nomatch[4], rx_nomatch[5], rx_nomatch[6], rx_nomatch[7] ],
    #)
    ##assert_equal(
      ##string,
      ##@o.recombine(rx_match, rx_nomatch).join,
    ##)
  #end

  #def test_section_and_markup()
    ## Given a complex document, with sections to be processed and sections to be ignored.
    #string = <<-heredoc.unindent
      #This is a complex document.
      
      #<html>
      #This should *not* be processed at all.
      #</html>
      
      #This *should* be processed.
    #heredoc
    #expected = <<-heredoc.unindent
      #This is a complex document.
      
      #<html>
      #This should *not* be processed at all.
      #</html>
      
      #This <strong>should</strong> be processed.
    #heredoc
    #assert_equal(
      #expected,
      #@o.markup( string, false )
    #)
  #end
# \n</html>\n\nThis <strong>should</strong> be processed.\n",
# \n       \n\nThis <strong>should</strong> be processed.\n".

end # class Test_Markup < MiniTest::Unit::TestCase




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


-------------------


s = "====Testing testing one two three"
rx = %r{(=+)}
puts s.match(rx).to_s.length
# => 4
