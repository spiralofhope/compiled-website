# Used in  class Test_Common < MiniTest::Unit::TestCase
# http://bfts.rubyforge.org/minitest/
require 'minitest/autorun'

class Test_Common < MiniTest::Unit::TestCase

  def setup()
    #
  end

  def test_unindent1()
    string = <<-heredoc
      one
      two
    heredoc
    expected = "one\ntwo\n"
    result = string.unindent
    assert_equal(
      expected,
      result
    )
  end

  def test_unindent2()
    string   = "one\ntwo\n"
    expected = "one\ntwo\n"
    result = string.unindent
    assert_equal(
      expected,
      result
    )
  end

  def test_unindent3()
    string = <<-heredoc
      one
       two
    heredoc
    expected = "one\n two\n"
    result = string.unindent
    assert_equal(
      expected,
      result
    )
  end

  # The first indentation becomes the maximum indentation to remove.
  def test_unindent4()
    string = <<-heredoc
       one
      two
        three
    heredoc
    expected = "one\ntwo\n three\n"
    result = string.unindent
    assert_equal(
      expected,
      result
    )
  end

end
