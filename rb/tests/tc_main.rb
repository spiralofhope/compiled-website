# Used in  class Test_Markup < MiniTest::Unit::TestCase
# http://bfts.rubyforge.org/minitest/
require 'minitest/autorun'

class Test_Markup < MiniTest::Unit::TestCase

  def setup()
    @o = Markup.new
  end

  def test_split_string_html()
    # Odd matches.
    # Even does not match.
    # Always an odd number of elements.
    #
    #
    string = 'nothing'
    expected = [
      string,
      '',
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal_array( expected, result )
    #
    #
    string = '<a>html</a>'
    expected = [
      '',
      string,
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal_array( expected, result )
    #
    # Trailing html tags are counted as strings.
    string = '<a>html</a><a>'
    expected = [
      '',
      '<a>html</a>',
      '<a>',
    ]
    result = @o.split_string_html( string )
    assert_equal_array( expected, result )
    #
    # Valid HTML has content within the tags.
    string = '<>html</>'
    expected = [
      string,
      '',
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal_array( expected, result )
    #
    # Valid HTML has matching content within the tags.
    string = '<a>html</b>'
    expected = [
      string,
      '',
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal_array( expected, result )
    #
    # Text before and after.
    string = 'before <a>html</a> after'
    expected = [
      'before ',
      '<a>html</a>',
      ' after',
    ]
    result = @o.split_string_html( string )
    assert_equal_array( expected, result )
    #
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
    assert_equal_array( expected, result )
    #
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
    assert_equal_array( expected, result )
    #
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
    assert_equal_array( expected, result )
    #
    # Improperly-nested instances of the same HTML tags.
    # This is user-error and is invalid HTML.
    #   TODO:  Check, is it invalid?  Isn't nesting tags valid?
    # HTML Tidy can clean this kind of code up.
    # TODO:  It would be nice to be able to deal with this sort of problem, but perhaps I can use HTML tidy on small blocks of code like this, before processing them myself.
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
    assert_equal_array( expected, result )
=end
    #
    # Garbage.
    string = '<foo bar="baz > quux">no</bar> yes </baz>no</>'
    expected = [
      string,
      '',
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal_array( expected, result )
    #
    # Painfully complex.
    string = '<tag bar="baz > quux">no</tag>'
    expected = [
      '',
      string,
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal_array( expected, result )
    #
    # Mind-numbingly complex.
    string = '<tag bar="</tag>">text</tag>'
    expected = [
      '',
      string,
      '',
    ]
    result = @o.split_string_html( string )
    assert_equal_array( expected, result )
    #
    #
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
    result = @o.split_string_html( string )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      <table>
       <tr><td></td></tr>
      </table>
    heredoc
    expected = [
      '',
      string.chomp,
      "\n",
    ]
    result = @o.split_string_html( string )
    assert_equal_array( expected, result )
    #
    #
  end # test_split_string_html()

  def test_not_in_html()
    # Note that more complex testing has already been done within test_split_string()
    # So I'm not getting too complex here, but just testing the not_in_html_test_method() use of yield.
    def not_in_html_test_method(
                                  string,
                                  *array
                                )
      if array.size > 0 then
        append = ' ' + array[0..-1].join( ' ' )
      else
        append = ''
      end
      string = "{#{ string }}#{append}"
      return string
    end
    #
    #
    string = 'one'
    expected = '{one}'
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i ) }
    assert_equal( expected, result )
    #
    # Remember that <> and </> are not proper HTML.
    string = 'one <>two</>'
    expected = '{one <>two</>}'
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i ) }
    assert_equal( expected, result )
    #
    #
    string = 'one <em>two</em>'
    expected = '{one }<em>two</em>'
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i ) }
    assert_equal( expected, result )
    #
    #
    string = 'one <em>two</em> three'
    expected = '{one }<em>two</em>{ three}'
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i ) }
    assert_equal( expected, result )
    #
    #
    string = 'one <em>two</em> three <em>four</em> five'
    expected = '{one }<em>two</em>{ three }<em>four</em>{ five}'
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i ) }
    assert_equal( expected, result )
    #
    #
    string = 'one <em>two</em> three <em>four</em> five'
    expected = '{one } hey more<em>two</em>{ three } hey more<em>four</em>{ five} hey more'
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i, 'hey', 'more' ) }
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
      <em>
        html
      </em>
      regular text
    heredoc
    # Remove that starting \n
    expected = <<-heredoc.unindent
      {}<em>
        html
      </em>{
      regular text
      }
    heredoc
    expected.chomp!
    result = @o.not_in_html( string ) { |i| not_in_html_test_method( i ) }
    assert_equal( expected, result )
    #
    #
  end # test_not_in_html()

  def test_markup_underline()
    #
    #
    string = '_underlined_'
    expected = '<u>underlined</u>'
    result = @o.markup_underline( string )
    assert_equal( expected, result )
    #
    #
    string = 'one _two_ three _four_'
    expected = 'one <u>two</u> three <u>four</u>'
    result = @o.markup_underline( string )
    assert_equal( expected, result )
    #
    #
    string = '<> _not underlined_ </>'
    expected = string
    result = @o.markup_underline( string )
    assert_equal( expected, result )
    #
    #
    string = '<>_not underlined_</>'
    expected = string
    result = @o.markup_underline( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        _not
        underlined_
      heredoc
    expected = string
    result = @o.markup_underline( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        <em>
        _not underlined_
        </em>
      heredoc
    expected = string
    result = @o.markup_underline( string )
    assert_equal( expected, result )
    #
    #
    string = '<em>_not underlined_</em>'
    expected = string
    result = @o.markup_underline( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
      <em>
      _not underlined_
      </em>
      <em>
      _not underlined_
      </em>
    heredoc
    expected = string
    result = @o.markup_underline( string )
    assert_equal( expected, result )
    #
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
    expected = string
    result = @o.markup_underline( string )
    assert_equal( expected, result )
=end
    #
    #
  end # test_markup_underline()

  def test_multiple_markup()
    #
    #
    string = '_underlined_ and *strong*'
    expected = '<u>underlined</u> and <strong>strong</strong>'
    result = @o.markup_everything( string )
    assert_equal( expected, result )
    #
    #
  end # test_multiple_markup()

  def test_nested_markup()
    #
    # This demonstrates how the first markup's html-result will stop any future markup from acting within that html.
    string = '_*underlined*_ *strong*'
    expected = '<u>*underlined*</u> <strong>strong</strong>'
    result = @o.markup_everything( @o.markup_underline( string ) )
    assert_equal( expected, result )
    #
    #
  end # test_nested_markup()

  def test_big()
    #
    #
    string = '**big**'
    expected = '<big>big</big>'
    result = @o.markup_big( @o.markup_underline( string ) )
    assert_equal( expected, result )
    #
    # This demonstrates the need for markup done in a specific order.  Big has to be performed before bold.
    string = '**big**'
    expected = '<big>big</big>'
    result = @o.markup_everything( @o.markup_underline( string ) )
    assert_equal( expected, result )
    #
    #
  end # test_big()

  def test_emphasis()
    #
    # Also testing within parens.
    string = '(/emphasis/)'
    expected = '(<em>emphasis</em>)'
    result = @o.markup_emphasis( string )
    assert_equal( expected, result )
    #
    #
  end # test_emphasis()

  def test_split_string_by_line()
    #
    # String doesn't match.
    string = <<-heredoc.unindent
      An example string
    heredoc
    rx = %r{does not match}
    expected = [
      string,
    ]
    result = @o.split_string_by_line( string, rx )
    assert_equal_array( expected, result )
    #
    # A line matches.
    string = <<-heredoc.unindent
      one
      two
      three
      four
    heredoc
    rx = %r{two}
    expected = [
      "one\n",
      "two\n",
      "three\nfour\n",
    ]
    result = @o.split_string_by_line( string, rx )
    assert_equal_array( expected, result )
    #
    # Using HTML.
    # Lines which match, but are inside HTML, are not considered matches.
    # TODO / FIXME - what the heck was I testing for?
    #string = <<-heredoc.unindent
      #one
      #<html>
      #two
      #</html>
      #two
      #two
      #two
      #three
      #four
    #heredoc
    #rx = %r{two}
    #expected = [ string ]
    #result = @o.split_string_by_line_and_html( string, rx )
    #p result
    #assert_equal_array( expected, result )
    #
    ## String doesn't match.  Strip leading spaces. (omitted .unindent)
    # TODO:  Functionality not yet re-implemented.
    #string = <<-heredoc
      #one
      #two
    #heredoc
    #rx = %r{does not match}
    #expected = [
      #"one\ntwo\n",
    #]
    #result = @o.split_string_by_line( string, rx, lstrip=true )
    #assert_equal_array( expected, result )
    #
    #
  end # test_split_string_by_line()

  def test_sections()
    #
    #
    string = <<-heredoc.unindent
      This is an example document.
    heredoc
    expected = [
      "This is an example document.\n",
    ]
    result = @o.split_string_sections( string )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      = Title One =
    heredoc
    expected = [
      '',
      "= Title One =\n",
    ]
    result = @o.split_string_sections( string )
    assert_equal_array( expected, result )
    #
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
    assert_equal_array( expected, result )
    #
    #
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
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      = 1 =
    heredoc
    expected = <<-heredoc.unindent
      <div class="s1"><h1>1</h1></div>
    heredoc
    result = @o.sections( string ).join + "\n"
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
      === 3 ===
    heredoc
    expected = <<-heredoc.unindent
      <div class="s1"><div class="s2"><div class="s3"><h3>3</h3></div></div></div>
    heredoc
    result = @o.sections( string ).join + "\n"
    assert_equal( expected, result )
    #
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
    assert_equal( expected, result )
    #
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
    assert_equal( expected, result )
    #
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
    assert_equal( expected, result )
    #
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
    assert_equal( expected, result )
    #
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
    assert_equal( expected, result )
    #
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
    assert_equal( expected, result )
    #
    #
  end # test_sections()

  def test_paragraphs()
    #
    #
    string = 'foo'
    expected = '<p>foo</p>'
    result = @o.paragraphs( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
      one
      
      two
    heredoc
    string.chomp!
    expected = <<-heredoc.unindent
      <p>one</p>
      <p>two</p>
    heredoc
    expected.chomp!
    result = @o.paragraphs( string )
    assert_equal( expected, result )
    #
    # Multiple line breaks.
    string = <<-heredoc.unindent
      one
      
      
      two
    heredoc
    string.chomp!
    expected = <<-heredoc.unindent
      <p>one</p>
      <br />
      <p>two</p>
    heredoc
    expected.chomp!
    result = @o.paragraphs( string )
    assert_equal( expected, result )
    #
    # Many line breaks.
    string = <<-heredoc.unindent
      one
      
      
      
      
      two
    heredoc
    string.chomp!
    expected = <<-heredoc.unindent
      <p>one</p>
      <br />
      <br />
      <br />
      <p>two</p>
    heredoc
    expected.chomp!
    result = @o.paragraphs( string )
    assert_equal( expected, result )
    #
    # Skip HTML content.
    string = <<-heredoc.unindent
      <pre>
      one
      
      two
      </pre>
    heredoc
    string.chomp!
    expected = <<-heredoc.unindent
      <p><pre>
      one
      
      two
      </pre></p>
    heredoc
    expected.chomp!
    result = @o.paragraphs( string )
    assert_equal( expected, result )
    #
    #
  end # test_paragraphs()

  def test_horizontal_rules()
    #
    #
    string = <<-heredoc.unindent
        line one
      heredoc
    expected = string
    result = @o.horizontal_rules( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        line one
        
        --
        
        line two
      heredoc
    expected = <<-heredoc.unindent
        line one
        
        <hr>
        
        line two
      heredoc
    result = @o.horizontal_rules( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        line one
        --
        line two
      heredoc
    expected = <<-heredoc.unindent
        line one
        <hr class="small">
        line two
      heredoc
    result = @o.horizontal_rules( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        Test >
        --
        
        content
      heredoc
    expected = <<-heredoc.unindent
        Test >
        <hr class="small">
        
        content
      heredoc
    result = @o.horizontal_rules( string )
    assert_equal( expected, result )
    #
    #
  end # test_horizontal_rules()

  def test_links_plain()
    #
    #
    string = <<-heredoc.unindent
        foo
      heredoc
    expected = string
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://example.com
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com">http://example.com</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        before http://example.com after
      heredoc
    expected = <<-heredoc.unindent
        before <a href="http://example.com">http://example.com</a> after
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://example.com/
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com/">http://example.com/</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://example.com/foo
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com/foo">http://example.com/foo</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://example.com/foo/
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com/foo/">http://example.com/foo/</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://127.0.0.1
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://127.0.0.1">http://127.0.0.1</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://127.0.0.1/
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://127.0.0.1/">http://127.0.0.1/</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://127.0.0.1/foo
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://127.0.0.1/foo">http://127.0.0.1/foo</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://127.0.0.1/foo/
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://127.0.0.1/foo/">http://127.0.0.1/foo/</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://example.com:1234
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com:1234">http://example.com:1234</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://example.com:1234/
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com:1234/">http://example.com:1234/</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://example.com:1234/foo
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com:1234/foo">http://example.com:1234/foo</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        http://example.com:1234/foo/
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com:1234/foo/">http://example.com:1234/foo/</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        line one
        http://example.com/foo/index.php?bar|baz#quux
        line two
        http://example.com:1234/foo/
      heredoc
    expected = <<-heredoc.unindent
        line one
        <a href="http://example.com/foo/index.php?bar|baz#quux">http://example.com/foo/index.php?bar|baz#quux</a>
        line two
        <a href="http://example.com:1234/foo/">http://example.com:1234/foo/</a>
      heredoc
    result = @o.links_plain( string )
    assert_equal( expected, result )
    #
    #
  end # test_links_plain()

  def test_links_named()
    #
    #
    string = <<-heredoc.unindent
        foo
      heredoc
    expected = string
    result = @o.links_named( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        [http://example.com foo]
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com">foo</a>
      heredoc
    result = @o.links_named( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        [http://example.com two words]
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com">two words</a>
      heredoc
    result = @o.links_named( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        before [http://example.com two words] after
      heredoc
    expected = <<-heredoc.unindent
        before <a href="http://example.com">two words</a> after
      heredoc
    result = @o.links_named( string )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        line one
        before [http://example.com/foo/index.php?bar|baz#quux foo bar] after
        line two
        before [http://example.com two words] after
      heredoc
    expected = <<-heredoc.unindent
        line one
        before <a href="http://example.com/foo/index.php?bar|baz#quux">foo bar</a> after
        line two
        before <a href="http://example.com">two words</a> after
      heredoc
    result = @o.links_named( string )
    assert_equal( expected, result )
    #
    #
  end # test_links_named()

  def test_links_numbered()
    #
    #
    string = <<-heredoc.unindent
        foo
      heredoc
    expected = string
    result = @o.links_numbered( string,
                                '',
                                '',
                                '',
                                '',
                                1
                                )
    result = result[0]
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        [http://example.com]
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com">1</a>
      heredoc
    result = @o.links_numbered( string,
                                '',
                                '',
                                '',
                                '',
                                0
                                )
    result = result[0]
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        before [http://example.com] after
      heredoc
    expected = <<-heredoc.unindent
        before <a href="http://example.com">1</a> after
      heredoc
    result = @o.links_numbered( string,
                                '',
                                '',
                                '',
                                '',
                                0
                                )
    result = result[0]
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        [http://example.com]
      heredoc
    expected = <<-heredoc.unindent
        <a href="http://example.com">[1]</a>
      heredoc
    result = @o.links_numbered( string,
                                '',
                                '',
                                '[',
                                ']',
                                0
                                )
    result = result[0]
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        [http://example.com]
      heredoc
    expected = <<-heredoc.unindent
        [<a href="http://example.com">1</a>]
      heredoc
    result = @o.links_numbered( string,
                                '[',
                                ']',
                                '',
                                '',
                                0
                                )
    result = result[0]
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        [http://example.com]
        [http://exampletwo.com]
      heredoc
    expected = <<-heredoc.unindent
        [<a href="http://example.com">a1b</a>]
        [<a href="http://exampletwo.com">a2b</a>]
      heredoc
    result = @o.links_numbered( string,
                                '[',
                                ']',
                                'a',
                                'b',
                                0
                                )
    result = result[0]
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
        [http://example.com]
        a [http://exampletwo.com] b
      heredoc
    expected = <<-heredoc.unindent
        [<a href="http://example.com">a1b</a>]
        a [<a href="http://exampletwo.com">a2b</a>] b
      heredoc
    result = @o.links_numbered( string,
                                '[',
                                ']',
                                'a',
                                'b',
                                0
                                )
    result = result[0]
    assert_equal( expected, result )
    #
    # Don't link this sort of thing.  Someone's being retarded and is mixing in the syntax for a new link.
    string = <<-heredoc.unindent
        [[http://example.com]]
      heredoc
    expected = <<-heredoc.unindent
        [[http://example.com]]
      heredoc
    result = @o.links_numbered( string,
                                '',
                                '',
                                '[',
                                ']',
                                0
                                )
    result = result[0]
    assert_equal( expected, result )
    #
    #
  end # test_links_numbered()

  # Naughty tests touch the disk.
  def test_links_automatic()
    verbose_old = $VERBOSE
    $VERBOSE = false
    create_file( '/tmp/foo.asc' )
    create_file( '/tmp/bar.asc' )
    create_file( '/tmp/foo-bar.asc' )
    create_file( '/tmp/bar-foo-bar.asc' )
    create_file( '/tmp/compiled-website-test-file.asc' )
    #
    # Simple match
    string = <<-heredoc.unindent
      foo
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo.html">foo</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    # Case-insensitive match.
    string = <<-heredoc.unindent
      Foo
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo.html">Foo</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    # Only link the first word.
    string = <<-heredoc.unindent
      foo foo
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo.html">foo</a> foo
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
skip "ungh, my philosophy is wrong for not_in_html(), I need another wrapper to only intelligently do that *per-line* or some sort of block_not_in_html()"
    #
    # Only link the first word.
    string = <<-heredoc.unindent
      foo <a href="a">a</a> foo
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo.html">foo</a> <a href="a">a</a> foo
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
      bar
    heredoc
    expected = <<-heredoc.unindent
      <a href="bar.html">bar</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    # Links two words, and don't link single words.
    string = <<-heredoc.unindent
      foo bar
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo-bar.html">foo bar</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    # Multi-word matches
    string = <<-heredoc.unindent
      compiled website test file
    heredoc
    expected = <<-heredoc.unindent
      <a href="compiled-website-test-file.html">compiled website test file</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    # Multi-word matches, where there are dashes.
    string = <<-heredoc.unindent
      compiled-website test file
    heredoc
    expected = <<-heredoc.unindent
      <a href="compiled-website-test-file.html">compiled-website test file</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
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
    assert_equal( expected, result )
    #
    # Allow matching within punctuation and specific endings
    string = <<-heredoc.unindent
      fooed
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo.html">foo</a>ed
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    # Match, ignoring dashes in the source text.
    string = <<-heredoc.unindent
      compiled-website test file
    heredoc
    expected = <<-heredoc.unindent
      <a href="compiled-website-test-file.html">compiled-website test file</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    # Don't link the current document's name.
    string = <<-heredoc.unindent
      foo
    heredoc
    expected = <<-heredoc.unindent
      foo
    heredoc
    source_file_full_path = '/tmp/foo.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    # Prioritizing two words before single words.
    string = <<-heredoc.unindent
      foo bar foo bar
    heredoc
    expected = <<-heredoc.unindent
      <a href="foo-bar.html">foo bar</a> <a href="foo.html">foo</a> <a href="bar.html">bar</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    # Multiple separate matches.
    string = <<-heredoc.unindent
      bar foo
    heredoc
    expected = <<-heredoc.unindent
      <a href="bar.html">bar</a> <a href="foo.html">foo</a>
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    # Maybe I can still have improved matching without being too slow.  I don't want to match the 'pre' in 'preview' and so I could still require at least a small subset of punctuation can't i?  Investigate.
    string = <<-heredoc.unindent
      abcfoodef
    heredoc
    expected = <<-heredoc.unindent
      abcfoodef
    heredoc
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    #
    string = '<a></a>DISPLAY<b></b> foo'
    expected = '<a></a>DISPLAY<b></b> <a href="foo.html">foo</a>'
    source_file_full_path = '/tmp/something.asc'
    result = @o.links_automatic( string, source_file_full_path )
    assert_equal( expected, result )
    #
    #
    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/bar.asc' )
    File.delete( '/tmp/foo-bar.asc' )
    File.delete( '/tmp/bar-foo-bar.asc' )
    File.delete( '/tmp/compiled-website-test-file.asc' )
    $VERBOSE = verbose_old
  end # test_links_automatic()

  # Naughty tests touch the disk.
  def test_links_local_new()
    # FIXME:  None of this is appropriate for other computers.  Refer to the $TEMP variable or some such.
    # TODO:  Investigate a temporary file space of some sort.  I think there's some kind of built-in function in Ruby 1.9 which gives temp files.
    verbose_old = $VERBOSE ; $VERBOSE = false
    filename = '/tmp/foo.asc'
    File.delete( filename       ) if File.exists?( filename )
    File.delete( '/tmp/bar.asc' ) if File.exists?( '/tmp/bar.asc' )
    File.delete( '/tmp/baz.asc' ) if File.exists?( '/tmp/baz.asc' )
    #
    # Standard usage.  Create a new empty file and link to it.
    create_file( filename, '[[bar]]' )
    string = file_read( filename )
    expected = '<a class="new" href="file:///tmp/bar.asc">bar</a>'
    result = @o.links_local_new( string, filename )
    assert_equal( expected, result )
    File.delete( filename )
    File.delete( '/tmp/bar.asc' )
    #
    # Standard usage.  Create a new empty file and link to it.
    create_file( filename, 'before [[bar]] after' )
    string = file_read( filename )
    expected = 'before <a class="new" href="file:///tmp/bar.asc">bar</a> after'
    result = @o.links_local_new( string, filename )
    assert_equal( expected, result )
    File.delete( filename )
    File.delete( '/tmp/bar.asc' )
    #
    # Standard usage.  [[ bar]] should not become a link!
    # Standard usage.  Create a new empty file and link to it.
    create_file( filename, '[[ bar]]' )
    string = file_read( filename )
    expected = '[[ bar]]'
    result = @o.links_local_new( string, filename )
    assert_equal( expected, result )
    File.delete( filename )
    #
    # Standard usage.  [[bar ]] should not become a link!
    # Standard usage.  Create a new empty file and link to it.
    create_file( filename, '[[bar ]]' )
    string = file_read( filename )
    expected = '[[bar ]]'
    result = @o.links_local_new( string, filename )
    assert_equal( expected, result )
    File.delete( filename )
    #
    # Standard usage.  [[ bar ]] should not become a link!
    # Standard usage.  Create a new empty file and link to it.
    create_file( filename, '[[ bar ]]' )
    string = file_read( filename )
    expected = '[[ bar ]]'
    result = @o.links_local_new( string, filename )
    assert_equal( expected, result )
    File.delete( filename )
    #
    # Second usage.  Remove [[ ]] for non-empty and already-existing files, to allow links_automatic() to operate.
    # An empty file is referenced.  Therefore keep [[ ]]
    create_file( filename, '[[bar]]' )
    create_file( '/tmp/bar.asc' )
    string = file_read( filename )
    expected = '<a class="new" href="file:///tmp/bar.asc">bar</a>'
    result = @o.links_local_new( string, filename )
    assert_equal( expected, result )
    File.delete( filename )
    File.delete( '/tmp/bar.asc' )
    #
    # Second usage.  Remove [[ ]] for non-empty and already-existing files, to allow links_automatic() to operate.
    # A non-empty file is referenced.  Therefore remove [[ ]]
    create_file( filename, '[[bar]]' )
    create_file( '/tmp/bar.asc', 'non-empty' )
    string = file_read( filename )
    expected = 'bar'
    result = @o.links_local_new( string, filename )
    assert_equal( expected, result )
    File.delete( filename )
    File.delete( '/tmp/bar.asc' )
    #
    # Testing two-word references.
    create_file( filename, '[[bar baz]]' )
    string = file_read( filename )
    expected = '<a class="new" href="file:///tmp/bar-baz.asc">bar baz</a>'
    result = @o.links_local_new( string, filename )
    assert_equal( expected, result )
    File.delete( filename )
    File.delete( '/tmp/bar-baz.asc' )
    #
    # Testing creating two new files.
    create_file( filename, '[[bar]] [[baz]]' )
    string = file_read( filename )
    expected = '<a class="new" href="file:///tmp/bar.asc">bar</a> <a class="new" href="file:///tmp/baz.asc">baz</a>'
    result = @o.links_local_new( string, filename )
    assert_equal( expected, result )
    File.delete( filename )
    File.delete( '/tmp/bar.asc' )
    File.delete( '/tmp/baz.asc' )
    #
    #
    $VERBOSE = verbose_old
  end # test_links_local_new()

  # Naughty tests touch the disk.
  def test_links_mixed()
    verbose_old = $VERBOSE ; $VERBOSE = false
    filename = '/tmp/foo.asc'
    # automatic and new.
    File.delete( filename        ) if File.exists?( filename )
    File.delete( '/tmp/bar.asc'  ) if File.exists?( '/tmp/bar.asc' )
    File.delete( '/tmp/baz.asc'  ) if File.exists?( '/tmp/baz.asc' )
    File.delete( '/tmp/quux.asc' ) if File.exists?( '/tmp/quux.asc' )
    #
    # Testing creating two new files.
    # [[baz]] already exists and is non-empty.  It should be auto-linked.
    create_file( '/tmp/foo.asc', '[[bar]] [[baz]] [[quux]]' )
    create_file( '/tmp/baz.asc', 'non-empty' )
    string = file_read( filename )
    expected = '<a class="new" href="file:///tmp/bar.asc">bar</a> <a href="baz.html">baz</a> <a class="new" href="file:///tmp/quux.asc">quux</a>'
    result = @o.links_local_new( string, filename )
    result = @o.links_automatic( result, filename )
    assert_equal( expected, result )
    File.delete( '/tmp/bar.asc' )
    File.delete( '/tmp/quux.asc' )
    File.delete( '/tmp/foo.asc' )
    File.delete( '/tmp/baz.asc' )
    #
    #
    $VERBOSE = verbose_old
  end # test_links_mixed()

  def test_lists_arrays()
    #
    #
    string = <<-heredoc.unindent
      foo
    heredoc
    expected = [ string ]
    result = @o.lists_arrays( string )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      - one
    heredoc
    expected = [
      '',
      string,
    ]
    result = @o.lists_arrays( string )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      # one
    heredoc
    expected = [
      '',
      string,
    ]
    result = @o.lists_arrays( string )
    assert_equal_array( expected, result )
    #
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
    assert_equal_array( expected, result )
    #
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
    assert_equal_array( expected, result )
    #
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
    assert_equal_array( expected, result )
    #
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
    assert_equal_array( expected, result )
    #
    # Single blank lines are allowed, but removed, merging the lists.
    # TODO:  Not re-implemented in this version!
    #string = <<-heredoc.unindent
      #- one
      
      #- two
      #- three
    #heredoc
    #expected = [
      #'',
      #"- one\n- two\n- three\n",
    #]
    #result = @o.lists_arrays( string )
    #assert_equal_array( expected, result )
    #
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
    assert_equal_array( expected, result )
    #
    # Indentation is allowed, but removed.
    # TODO:  Not re-implemented in this version!
    #string = <<-heredoc
      #- one
      
      
      #- two
      #- three
    #heredoc
    #expected = [
      #'',
      #"- one\n",
      ## yes, the whitespace is kept for the non-list lines.
      #"      \n      \n",
      #"- two\n- three\n",
    #]
    #result = @o.lists_arrays( string )
    #assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      - list
      
      one
      
      two
    heredoc
    result = @o.lists_arrays( string )
    expected = [
      '',
      "- list\n",
      "\none\n\ntwo\n",
    ]
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      <a>
      # one
      </a>
    heredoc
    expected = [ string ]
    #result = @o.lists_arrays( string )
    result = @o.split_string_by_line( string, %r{^\ *[-|\#]+\ +.+?$}, true )
    #assert_equal_array( expected, result )
    #
    #
  end # test_lists_arrays()

  def test_lists()
    # TODO:  Mixed lists, incrementing a lot.
    # TODO:  Mixed lists, incrementing then decrementing a lot.
    #
    #
    string = <<-heredoc.unindent
      foo
    heredoc
    expected = <<-heredoc.unindent
      foo
    heredoc
    result = @o.lists( string )
    assert_equal( expected, result )
    #
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
    assert_equal( expected, result )
    #
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
    assert_equal( expected, result )
    #
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
    assert_equal( expected, result )
    #
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
    assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
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
    # FIXME
    #assert_equal( expected, result )
    #
    string = <<-heredoc.unindent
        - foo
        # bar
      heredoc
    expected = <<-heredoc.unindent
        <ul>
        <li>one</li>
        </ul>
        <ol>
        <li>two</li>
        </ol>
      heredoc
    expected.chomp!
    result = @o.lists( string )
    # TODO:  Mixed lists
    # FIXME
    #assert_equal( expected, result )
    #
    # And now let's try to break the damned thing!
    string = <<-heredoc.unindent
      -- one
      ## two
      - three
      -- four
      --- five
      -----
      # oh
      ### here
      heredoc
    expected = <<-heredoc.unindent
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
    expected.chomp!
    result = @o.lists( string )
    # FIXME
    # TODO:  Mixed lists
    #assert_equal( expected, result )
    #
    #
  end # def test_lists()

  def test_blocks_array()
    #
    # No match, no whitespace leading any lines ( I'm using heredoc.unindent )
    string = <<-heredoc.unindent
      one
      two
    heredoc
    expected = [ "one\ntwo\n" ]
    result = @o.blocks_array( string )
    assert_equal_array( expected, result )
    #
    # A basic match.
    # Preserve all whitespace. ( I'm not using heredoc.unindent )
    string = <<-heredoc
      one
      two
    heredoc
    expected = [
      '',
      "      one\n      two\n",
    ]
    result = @o.blocks_array( string )
    assert_equal_array( expected, result )
    #
    # Text before and after.  ( .unindent will preserve the tabbing of the lines with 'one' and 'two' )
    string = <<-heredoc.unindent
      before
        one
        two
      after
    heredoc
    expected = [
      "before\n",
      "  one\n  two\n",
      "after\n",
    ]
    result = @o.blocks_array( string )
    assert_equal_array( expected, result )
    #
    # Multiple separate blocks, also with regular text.  ( .unindent will preserve the tabbing of the lines with 'one', 'two', 'three' and 'four' )
    string = <<-heredoc.unindent
      before
        one
        two
      after
      
        three
        four
    heredoc
    expected = [
      "before\n",
      "  one\n  two\n",
      "after\n\n",
      "  three\n  four\n"
    ]
    result = @o.blocks_array( string )
    assert_equal_array( expected, result )
    #
    #
  end # test_blocks_array()

  def test_blocks()
    #
    #
    string = <<-heredoc.unindent
      foo
    heredoc
    expected = <<-heredoc.unindent
      foo
    heredoc
    result = @o.blocks( string )
    assert_equal( expected, result )
    #
    #
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
    assert_equal( expected, result )
    #
    #
    string = <<-heredoc.unindent
      before
        some text
      after
    heredoc
    expected = <<-heredoc.unindent
      before
      <pre>some text
      </pre>
      after
    heredoc
    #expected.chomp!
    result = @o.blocks( string )
    assert_equal( expected, result )
    #
    #
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
      </pre>
      after
    heredoc
    #expected.chomp!
    result = @o.blocks( string )
    assert_equal( expected, result )
    #
    # Not processing html via not_in_html() is done at this level, and not within blocks() or blocks_array()
    string = <<-heredoc.unindent
      <table>
       <tr><td></td></tr>
      </table>
    heredoc
    expected = string
    result = @o.not_in_html( string ) { |i| @o.blocks(i) }
    assert_equal( expected, result )
    #
    # Make sure that any html code isn't being forced out of the pre block.  The pre block should include everything as long as it shares that same left column of spaces.
    # FIXME:  I'm getting my 'even number of elements' warning.
    string = '  before <html>should be on the same line</html> after'
    expected = "<pre>before <html>should be on the same line</html> after\n</pre>"
    result = @o.blocks( string )
    assert_equal( expected, result )
    #
    #
  end # def test_blocks()

  def test_line_partition_1()
    #
    # Given a string, a beginning and an ending.
    # Separate the string into an alternating array of matches and non-matches.
    # Output type one.  The matched blocks are placed inside.
    # [ ..., begin***end, ..., begin***end, ... ]
    string = <<-heredoc.unindent
      This is a string
      Line two
      Three
    heredoc
    match_array=[ 'BEGIN', 'END' ]
    expected = [ string ]
    result = line_partition(
                              string,
                              match_array
                            )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      This is a string
      BEGIN
      Line two
      END
      Three
    heredoc
    match_array = [ 'BEGIN', 'END' ]
    expected = [
      "This is a string\n",
      "BEGIN\nLine two\nEND\n",
      "Three\n",
    ]
    result = line_partition(
                              string,
                              match_array
                            )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      This is a string
      BEGIN
      Line two
      END
      Three
    heredoc
    match_array=[ %r{^BEGIN$}, %r{^END$} ]
    expected = [
      "This is a string\n",
      "BEGIN\nLine two\nEND\n",
      "Three\n",
    ]
    result = line_partition(
                              string,
                              match_array
                            )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      This is a string
      BEGIN
      Line two
      END
      Three
    heredoc
    match_array=[ %r{^BEGIN$}, %r{^END$} ]
    expected = [
      "This is a string\n",
      "Line two\n",
      "Three\n",
    ]
    result = line_partition(
                              string,
                              match_array,
                              'omit',
                              'omit'
                            )
    assert_equal_array( expected, result )
    #
    #
  end # test_line_partition_1()

  def test_line_partition_2()
    #
    # Output type two.  The matched blocks are placed outside.
    # [ ...begin, ***, end...begin, ***, end... ]
    string = <<-heredoc.unindent
      This is a string
      BEGIN
      Line two
      END
      Three
    heredoc
    match_array = [ 'BEGIN', 'END' ]
    expected = [
      "This is a string\nBEGIN\n",
      "Line two\n",
      "END\nThree\n",
    ]
    result = line_partition(
                              string,
                              match_array,
                              'out',
                              'out',
                            )
    assert_equal_array( expected, result )
    #
    #
    match_array = [ 'BEGIN', 'END' ]
    expected = [
      "This is a string\n",
      "BEGIN\nLine two\n",
      "END\nThree\n",
    ]
    result = line_partition(
                              string,
                              match_array,
                              'in',
                              'out',
                            )
    assert_equal_array( expected, result )
    #
    #
  end # test_line_partition_2()

  def test_line_partition_3()
    #
    #
    # Allow multiple separator triggers.
    string = <<-heredoc.unindent
      This is a string
      BEGIN
      Line two
      END
      Three
    heredoc
    match_array = [
                    [ 'BEGIN1', 'END1' ],
                    [ 'BEGIN2', 'END2' ]
                  ]
    expected = [
      "This is a string\nBEGIN\n",
      "Line two\n",
      "END\nThree\n",
    ]
    expected = [ string ]
    result = line_partition(
                              string,
                              match_array,
                              'out',
                              'out',
                            )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      This is a string
      BEGIN1
      Line two
      END1
      Three
    heredoc
    match_array = [
                    [ 'BEGIN1', 'END1' ],
                    [ 'BEGIN2', 'END2' ]
                  ]
    expected = [
      "This is a string\n",
      "BEGIN1\nLine two\nEND1\n",
      "Three\n",
    ]
    result = line_partition(
                              string,
                              match_array,
                            )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      This is a string
      BEGIN1
      Line two
      END1
      Three
    heredoc
    match_array = [
                    [ 'BEGIN1', 'END1' ],
                    [ 'BEGIN2', 'END2' ]
                  ]
    expected = [
      "This is a string\nBEGIN1\n",
      "Line two\n",
      "END1\nThree\n",
    ]
    result = line_partition(
                              string,
                              match_array,
                              'out',
                              'out',
                            )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      This is a string
      BEGIN2
      Line two
      END2
      Three
    heredoc
    match_array = [
                    [ 'BEGIN1', 'END1' ],
                    [ 'BEGIN2', 'END2' ]
                  ]
    expected = [
      "This is a string\nBEGIN2\n",
      "Line two\n",
      "END2\nThree\n",
    ]
    result = line_partition(
                              string,
                              match_array,
                              'out',
                              'out',
                            )
    assert_equal_array( expected, result )
    #
    #
  end # test_line_partition_3()

  def test_line_partition_4()
    #
    # Allow each separator trigger to have multiple beginnings and endings.
    string = <<-heredoc.unindent
      This is a string
      BEGIN1a
      Line two
      END1b
      Three
    heredoc
    match_array = [
                    [ [ 'BEGIN1a', 'BEGIN1b' ], [ 'END1a', 'END1b' ] ],
                    [ [ 'BEGIN2' ], [ 'END2' ] ]
                  ]
    expected = [
      "This is a string\nBEGIN1a\n",
      "Line two\n",
      "END1b\nThree\n",
    ]
    result = line_partition(
                              string,
                              match_array,
                              'out',
                              'out',
                            )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      This is a string
      BEGIN2
      Line two
      END2
      Three
    heredoc
    match_array = [
                    [ [ 'BEGIN1a', 'BEGIN1b' ], [ 'END1a', 'END1b' ] ],
                    [ [ 'BEGIN2' ], [ 'END2' ] ]
                  ]
    expected = [
      "This is a string\nBEGIN2\n",
      "Line two\n",
      "END2\nThree\n",
    ]
    result = line_partition(
                              string,
                              match_array,
                              'out',
                              'out',
                            )
    assert_equal_array( expected, result )
    #
    #
    string = <<-heredoc.unindent
      This is a string
      <foo bar="baz">
      Line two
      </foo>
      Three
    heredoc
    match_array = [ %r{^<}, %r{^<.*>$} ]
    expected = [
      "This is a string\n",
      "Line two\n",
      "Three\n",
    ]
    result = line_partition(
                              string,
                              match_array,
                              'omit',
                              'omit',
                            )
    assert_equal_array( expected, result )
    #
    #
  end # test_line_partition_4()

end # class Test_Markup < MiniTest::Unit::TestCase
