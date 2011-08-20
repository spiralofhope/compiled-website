=begin
yield thing
- to the inside block
- to the outside block
- to the begin match
- to the end match
---> just do one yield with four parameters.
- The yield will be acting per-line.  To do something per-element the user would just do a normal array.each{}
=end

class String
  def unindent()
    lines = Array.new
    self.each_line { |ln| lines << ln }
    first_line_ws = lines[0].match( /^\s*/ )[0]
    rx = Regexp.new( '^\s{0,' + first_line_ws.length.to_s + '}' )
    lines.collect { |line| line.sub( rx, '' ) }.join
  end
end

def line_partition(
                      string='',
                      match_array=[],
                      begin_in_or_out='in',
                      end_in_or_out='in'
                    )
  #
  return '' if string == nil
  return '' if match_array == []
  #
  if match_array[0].class == String then
    # using the simple syntax:  match_array = [ 'begin', 'end' ]
    #                       =>
    #                                         [ [ [ 'begin' ], [ 'end' ] ] ]
    # Beef it up.
    match_array.each_index{ |i|
      match_array[i] = [ match_array[i] ]
    }
    match_array = [ match_array ]
    end
  if match_array[0][0].class == String then
    # using the syntax:  match_array = [
    #                                    [ 'begin1a', 'end1a' ],
    #                                    [ 'begin2a', 'end2a' ]
    #                                  ]
    #                => 
    #                                  [
    #                                    [ [ 'begin1a' ], [ 'end1b' ] ],
    #                                    [ [ 'begin2a' ], [ 'end2a' ] ]
    #                                  ]
    # Beef it up.
    match_array[0].each_index{ |i|
      match_array[i].each_index{ |j|
        match_array[i][j] = [ match_array[i][j] ]
      }
    }
  end
  #
  result = [ '' ]
  active_close_tags = []
  #
  string.each_line{ |line|
    #
    matched = false
    #
    if active_close_tags == [] then
      # We're looking for a begin match.
      match_array.each_index{ |i|
        match_array[i][0].each{ |j|
          if line.chomp == j.chomp then
            # We found a begin match.
            matched = true
            active_close_tags = match_array[i][1]
            result << ''
            if begin_in_or_out == 'in' then
              result[-1] += line
            else
              result[-2] += line
            end
            break
          end
        }
      }
      if matched == false then
        # No match.
        # Append it.
        result[-1] += line
      end
    else
      # We're in the middle of a block.
      # Look for an end match.
      active_close_tags.each{ |e|
        if line.chomp == e.chomp then
          matched = true
          active_close_tags = []
          # Match.  Found the end of a block.
          if end_in_or_out == 'in' then
            # Append the closing tag.
            result[-1] += line
            # Begin a new element.
            result << ''
          else
            result << line
          end
          break
        end
      }
      if matched == false then
        # No match.
        # Append it.
        result[-1] += line
      end
    end
  }
  return result
end

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

require 'minitest/autorun'
class Test_line_partition < MiniTest::Unit::TestCase
  def setup()
  end

  def test_line_partition_1()
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
  end

  def test_line_partition_2()
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
  end

  def test_line_partition_3()
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
  end

  def test_line_partition_4()
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
  end
end
