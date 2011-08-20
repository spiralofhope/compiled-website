# http://bfts.rubyforge.org/minitest/
require 'minitest/autorun'

# http://stackoverflow.com/questions/3772864/how-do-i-remove-leading-whitespace-chars-from-ruby-heredoc/4465640#4465640
class String
  # FIXME:  If there is no indenting, this explodes.  Good thing I always indent by at least two.

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

    first_line_ws = lines[0].match(/^\s+/)[0]
    re = Regexp.new('^\s{0,' + first_line_ws.length.to_s + '}')

    lines.collect {|line| line.sub(re, "") }.join
  end
end

class Markup_test

  def processable( rx,              # start_rx
                   end_rx,
                   process_should ) # string
    # TODO:  Sanity-checking
    # Convert the string into an array.
    process_should = [ process_should ]
    rx = %r{(#{rx})(.*?)(#{end_rx})}
    process_should_not = Array.new
    until process_should[-1].match( rx ) == nil do
      process_should.delete_at(-1)
      process_should << $`
      process_should << nil
      process_should << $'
      process_should_not << nil
      process_should_not << $~[1..3]
      process_should_not << nil
    end
    return process_should, process_should_not
  end
#Expected "<u>underlined</u><>_underlined_</>\n"
     #not "<u>underlined</u><>_underlined_</>\n<u>underlined</u>\n".

  # Array1 replaces its nils with content from array2
  def combine_arrays( array1, array2 )
    # TODO:  Sanity-checking
    array1.each_index do |i|
      if array1[i] == nil then
        array1[i] = array2[i]
      end
    end
    return array1
  end

  def markup( string )
    process_should, process_should_not = processable( %r{<.*?>}, %r{</.*?>}, string )
    process_should.each_index do |i|
      next if process_should[i] == nil
      # underline
      if process_should[i].match( %r{(_)(.*?)(_)} ) != nil then
        process_should[i] = $` + "<u>" + $~[2] + "</u>" + $'
      end
    end
    return combine_arrays( process_should, process_should_not ).join
  end

end

class Test_Markup_test < MiniTest::Unit::TestCase
  def setup()
    @o = Markup_test.new
    (
    @document = <<-heredoc.unindent
        ex.
        _underlined_
        <nowiki>
        _underlined_
        </nowiki>
        _underlined_
    heredoc
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
end


# --------------------------------


class Markup
  def initialize()
  end
  # TODO: re-usable sanity checking code
  def sanity_check( string )
    # is it a string?
    # try to convert it..
    return string
  end
  
  def block_processing( start_rx, end_rx, string )
    # TODO: Sanity-checking
    # Break the string into two arrays:
    #   1) Lines which should     be processed.
    #   2) Lines which should not be processed.
    process_should     = Array.new
    process_should_not = Array.new
    f = true
    string.each_line do |line|
      if    line.match( start_rx ) then
        f = false
      elsif line.match( end_rx   ) then
        f = true
      elsif f == true  then
        process_should     << line
        process_should_not << nil
      elsif f == false then
        process_should     << nil
        process_should_not << line
      else
        throw "explosion 1"
      end
    end
    return process_should, process_should_not
  end
  # TODO:  I need to walk through and have a process_should and process_should_not, just like the block processing.  I do not want to match within HTML -- which would also make <nowiki>_plain_</nowiki> work as expected.
  # >>>>> Steal/integrate the existing code I did.  Make sure I understand it completely first, and rewrite it only if necessary.
  def words_regex( rx, matched_start, matched_end, string )
    # TODO:  Sanity-checking
    #        - only accept lines, not blocks of string
    if string.match( rx ) == nil then
      return string
    end
    html = %r{<.+?>.*?</.+?>}
    if string.match( html ) == nil then
      string.match( rx )
      string.gsub!(
        rx,
        matched_start + $~[1] + matched_end,
      )
      return string
    end

  end
  def markup( string )
    # TODO: Sanity-checking

    process_should     = Array.new
    process_should_not = Array.new
    process_should, process_should_not = block_processing( %r{^<nowiki>$}, %r{^</nowiki>$}, string )

    # Now I have two arrays:  process_true, process_false
    # Process the array that's supposed to be processed
    process_should.each_index do |i|
      next if process_should[i] == nil
      process_should[i] = words_regex( %r{_(.+?)_}, "<u>", "</u>", process_should[i] )
    end
    
    # Re-combine the two arrays.
    # Step through one
    #   for anything nil, absorb content from the other.
    process_should.each_index do |i|
      if process_should[i] == nil then
        process_should[i] = process_should_not[i]
      end
    end
    result = ""
    process_should.each do |line|
      result = result + line
    end
    return result
  end
end

# http://bfts.rubyforge.org/minitest/MiniTest/Assertions.html
class Test_Markup < MiniTest::Unit::TestCase
  def setup()
    @o = Markup.new
    (
    @document = <<-heredoc.unindent
        ex.
        _underlined_
        <nowiki>
        _underlined_
        </nowiki>
        _underlined_
    heredoc
    )
  end

  def test_nowiki_block
    # Expecting the lines containing <nowiki> to be eliminated.
    assert_equal(
      ( <<-heredoc.unindent
        line one
        line two
        line three
      heredoc
      ),
      @o.markup( <<-heredoc.unindent
        line one
        <nowiki>
        line two
        </nowiki>
        line three
      heredoc
      ),
    )
    # Expecting the lines between <nowiki> to not be marked-up.
    assert_equal(
      ( <<-heredoc.unindent
        line one
        _line two_
        line three
      heredoc
      ),
      @o.markup( <<-heredoc.unindent
        line one
        <nowiki>
        _line two_
        </nowiki>
        line three
      heredoc
      ),
    )
  end
  
  def test_nowiki
  end

  def test_u()
    assert_equal(
      ( <<-heredoc.unindent
        ex.
        <u>underlined</u>
        _underlined_
        <u>underlined</u>
      heredoc
      ),
      @o.markup( @document ),
    )
  end
end

__END__

- How do I make my failures easier to read?  It's ugly being all on one line like that.
