# Used in  class Test_Common < MiniTest::Unit::TestCase
# http://bfts.rubyforge.org/minitest/
require 'minitest/autorun'

class Test_Common < MiniTest::Unit::TestCase

  def setup()
    #
  end

  def test_unindent_1()
    string = <<-heredoc
      one
      two
    heredoc
    expected = "one\ntwo\n"
    result = string.unindent
    assert_equal( expected, result )
  end

  def test_unindent_2()
    string   = "one\ntwo\n"
    expected = "one\ntwo\n"
    result = string.unindent
    assert_equal( expected, result )
  end

  def test_unindent_3()
    string = <<-heredoc
      one
       two
    heredoc
    expected = "one\n two\n"
    result = string.unindent
    assert_equal( expected, result )
  end

  # The first indentation becomes the maximum indentation to remove.
  def test_unindent_4()
    string = <<-heredoc
       one
      two
        three
    heredoc
    expected = "one\ntwo\n three\n"
    result = string.unindent
    assert_equal( expected, result )
  end

  def test_gpartition()
    # TODO
  end

  # Non-matches are returned as a one-element array.
  def test_gpartition2_1()
    string = 'This is a test'
    expected = [ string ]
    rx = %r{Not matching}
    result = string.gpartition2( rx )
    assert_equal_array( expected, result )
  end

  # Matches are returned as a three-element array.
  def test_gpartition2_2
    string = 'aaabbbcccddd'
    expected = [ 'aaa', 'bbb', 'cccddd' ]
    rx = %r{bbb}
    result = string.gpartition2( rx )
    assert_equal_array( expected, result )
  end

  # TODO:  More fierce gpartition2 test cases.
  #        Take ideas or move content from tc_main test cases.

end
