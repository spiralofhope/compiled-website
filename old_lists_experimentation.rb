string=<<-"HEREDOC"
- 1
-- 2
--- 3
-- 4
- 5

HEREDOC
result=[]
previous_nesting=0
# FIXME: This won't end correctly if the list ends with an EOF.  Not a big deal since TidyHTML will fix it, but I should code this better.
string.each do |line|
  # Search for a list with leading dashes.
  line =~ /^(-+) (.*)$/
  if $~ != nil then
    # I'm in a list.
    # Add the HTML elements to the line.
    line = "<li> " + $~[2] + " </li>"
    # Specify what nesting level I'm in.
    current_nesting = $~[1].length
    if current_nesting > previous_nesting then
      # I'm up a level.
      line="<ul> " + line
    elsif current_nesting < previous_nesting then
      # I'm down one or more levels.
      line=( "</ul> " * (previous_nesting - current_nesting)) + line
    else
      # I'm at the same level.
      # Nothing special needs to be done, I've already added the HTML elements to the line.
      line = line
    end
  else
    # not in a list.
    current_nesting=0
    if previous_nesting > 0 then
      # I'm down one or more levels (to the last level from a list).
      line=( "</ul> " * (previous_nesting - current_nesting)) + line
    else
      # I'm at the same level (I wasn't nested before).
      # Nothing special needs to be done.
      line = line
    end
  end
  previous_nesting=current_nesting
  result << line
end
puts result
__END__



string=<<-"HEREDOC"
not a list
- list1
- list2
no
HEREDOC
result=[]
previous_nesting=0
string.each do |line|
  if ( line =~ /^(-+) (.*)/ ) != nil then # found a list (any nesting level)
    # The actual content of the line, without the dashes.
    line=$~[2]
    # The number of dashes found.
    current_nesting=$~[1].length
    if current_nesting > previous_nesting then # I'm up a level.
      result << "<ul>" + "<li>" + line + "</li>"
    elsif current_nesting < previous_nesting then # I'm down a level.
      result  << "<li>" + line + "</li>" + "</ul>"
    else # no level change (but I'm still in a list)
      result << "<li>" + line + "</li>"
    end
    # The number of dashes found.
    previous_nesting=current_nesting
  else # Didn't find a list.
    if previous_nesting > 0 then # One or more lists have terminated
      result << "<li>" + line + "</li>" + ( "</ul>" * previous_nesting )
    else # I wasn't working on a list before.
      result << line
    end
  end
end
puts result
__END__



string=<<-"HEREDOC"
not a list
- list1
- list2
no
HEREDOC
result=[]
list=[]
string.each do |line|
  if ( line =~ /^- (.*)/ ) != nil then
    list << "<li>#{$~[1]}</li>"
  else
    if list!=[] then
      result << "<ul>" << list << "</ul>"
      list=[]
      result << line
    else
      result << line
    end
  end
end
puts result
__END__



