# This file is for stuff that could be used in entirely different Ruby projects.


class String
  # http://stackoverflow.com/questions/3772864/how-do-i-remove-leading-whitespace-chars-from-ruby-heredoc/4465640#4465640
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
  def unindent()
    lines = Array.new
    self.each_line { |ln| lines << ln }

    first_line_ws = lines[0].match( /^\s*/ )[0]
    rx = Regexp.new( '^\s{0,' + first_line_ws.length.to_s + '}' )

    lines.collect { |line| line.sub( rx, '' ) }.join
  end

  # like Array.partition, but "global", in the same sense that `sub` has `gsub`
  def gpartition( rx )
    a = self.partition( rx )
    until a[-1].match( rx ) == nil do
      a[-1] = a[-1].partition( rx )
      a.flatten!
    end
    # Returns an array
    # Odd are the non-matches
    # Even are the matches
    # Always returns an odd number of elements
    #p 'uneven size!' if a.size.even?
    return a
  end

  # Like gpartition, except instead of a non-match returning [ (string), '', '' ] it returns [ (string) ]
  def gpartition2( rx )
    verboseold = $VERBOSE ; $VERBOSE=nil
    def gpartition2_remove_consecutive_empty_strings( array )
      if array[-1] == '' and array[-2] == '' then
        array.pop(2)
      else
        array.flatten!
      end
      return array
    end
    #
    a = gpartition2_remove_consecutive_empty_strings( self.partition( rx ) )
    until a[-1].match( rx ) == nil do
      a[-1] = gpartition2_remove_consecutive_empty_strings( a[-1].partition( rx ) )
    end
    #
    $VERBOSE=nil ; verboseold = $VERBOSE
    return a
    #return   a   if a.class == array
    #p '------------ what the hell?'
    #return [ a ] if a.class == string
    #p a, a.class
  end
end
