=begin
1)
Given a string, a beginning and an ending.

foo(
      string,
      [
        [
          [ begin ],
          [ end ],
        ],
      ]
    )

Separate the string into an alternating array of matches and non-matches.
Output type one:
[ ..., begin***end, ..., begin***end, ... ]

2)
Output type two:
[ ...begin, ***, end...begin, ***, end... ]

foo(
      string,
      type,
      [
        [
          [ begin ],
          [ end ],
        ],
      ]
    )


3)
Allow multiple separator triggers.
foo(
      string,
      [
        [
          [ begin1 ],
          [ end1 ],
        ],
        [
          [ begin2 ],
          [ end2 ],
        ],
      ]
    )

4)
Allow each separator trigger to have multiple beginnings and endings.

foo(
      string,
      [
        [
          [ begin1a, begin1b ],
          [ end1a, end1b, end1c ],
        ],
        [
          [ begin2a, begin 2b ],
          [ end2a ],
        ],
      ]
    )


=end


class String
  def unindent()
    lines = Array.new
    self.each_line { |ln| lines << ln }

    first_line_ws = lines[0].match( /^\s*/ )[0]
    rx = Regexp.new( '^\s{0,' + first_line_ws.length.to_s + '}' )

    lines.collect { |line| line.sub( rx, "" ) }.join
  end
end

# --

def line_partition(
                      string=nil,
                      match_array=nil,
                      in_or_out=nil
                    )
  # Sanity checking.
  return '' if string == nil
  #
  # Default values.
  string      ||= ''
  match_array ||= []
  in_or_out   ||= true
  #
  result = [ '' ]
  close_tags = []
  match_begin = match_array[0]
  match_end   = match_array[1]
  string.each_line{ |line|
    if close_tags == [] then
      # We're looking for a begin match.
      if line.match( match_begin ) == nil then
        # No match.
        # Append it.
        result[-1] += line
      else
        # Match.  Found a new block.
        # Begin a new element.
        result << ''
        # Append it.
        result[-1] = line
        close_tags = [ match_end ]
      end
    else
      # We're in the middle of a block.
      # Look for an end match.
      if line.match( close_tags[0] ) == nil then
        # No match.
        # Append it.
        result[-1] += line
      else
        # Match.  Found the end of a block.
        # Append the closing tag.
        result[-1] += line
        # Begin a new element.
        result << ''
        # Tidy up, and expect the next opening tag.
        close_tags = []
      end
    end
  }
  return result
end

require 'minitest/autorun'
def assert_equal_array( expected, result )
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
class Test_line_partition < MiniTest::Unit::TestCase
  def setup()
  end
  def test_line_partition()
    #
    #
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
  end
end