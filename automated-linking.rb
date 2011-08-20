# TODO - automatic-linking.
#   I guess I would make some variation on chew.. not sure how I would do that.
# TODO - I don't think I can remove marked_yes, because that could be useful to make sure I don't have nested markup.
#   It's ok.  I can just have another markup called _/ and /_  which will combine two (or more) markups.  It'll work out..


# working_directory=File.expand_path(File.join('', 'home', 'user', 'live', 'Projects', 'compiled-website', '0.4.7'))
# lib = File.join(working_directory, 'lib')
# require File.join(lib, 'misc.rb')
# require File.join(lib, 'directories.rb')
# require File.join(lib, 'files.rb')
# require File.join(lib, 'strings.rb')

def marked_yes(string, search_left, search_right, replace_left, replace_right)
  if string == nil then return '' end
  # TODO: If a link, check that the destination exists
  #  - local = create the file
  #  - remote = check if it exists, and cache the results?  Only check once a day?
  return string.sub(search_left, replace_left).sub(search_right, replace_right)
end
def marked_no(string, internal_markup_flag)
  if string == nil then return '' end
  # TODO: Automatic-linking
  # TODO: My own markup
  if internal_markup_flag == true then
    internal_markup_flag=true
  else
    # TODO: I need to play around more with the regex to handle additional situations.
    string=chew(string, /(^| )\//, /\/( |.|$)/, '\1<em>', '</em>\1', true)
    string=chew(string, /(^| )_/, /_( |.|$)/, '\1<u>', '</u>\1', true)
    internal_markup_flag=false
  end
  return string
end

# TODO: Either do this per-line, or fix the regex and/or \n so that I can make it a whole-file thing.
def chew(string, search_left, search_right, replace_left, replace_right, internal_markup_flag)
  processed=""
  count=0
  until string == nil or count > 20 do
    count+=1
    string.match(/(#{search_left}.*?#{search_right})/)
    if $' != nil then
      string=$'
      processed=
        processed +
        marked_no($`, internal_markup_flag) +
        marked_yes($1, search_left, search_right, replace_left, replace_right)
    else
      # Deal with the remainder after a link.
      processed=processed + marked_no(string, internal_markup_flag)
      break # Stop this loop.
    end
  end
  return processed
end

document="/example/ text"
document="text [[with a link]] text _internal_ /markup/. [[with a link2]] etc."
document=chew(document, /\[\[/, /\]\]/, '<', '>', false)

puts document.inspect

__END__

def automated_linking()
end
def test_automated_linking()
#   working_directory=File.join('', 'tmp', "test_automated_linking.#{$$}")
#   working_directory=File.expand_path(working_directory)
#   mcd_directory(working_directory)
#   create_file(File.join(working_directory, 'file1.html'), '')

  document2=<<-HEREDOC
[[word1]][[word2]] [[word3]] [[two words]] [[12]] [[wordnum12]] [[]] [[.,-|\/]]
This is a [[two word]] [[example link]] line.
This one [[has, punctuation. which ! should? be - ok]]
This one [[has, punctuation.]]
A link [[on two
lines]] isn't possible.
[[not a link] ]
[ [not a link]]
[[an odd ] ] link]]
  HEREDOC


# puts count.inspect, process.inspect
until count==20 || process=='' do
  count+=1
  if process == nil then process="" ; next end
  process.match(/(\[\[.*?\]\])/)

  if $1 != nil then
    marked="<MARKUP>#{$`}</MARKUP>"
    final=final+marked+$1
    process=$'
    next
  else
    process=$'
  end


# puts process.inspect
end
puts document
puts '----'
puts final

#   return $` + replacement + $'



# stop=false
# until stop=true do
# end



  array[left..right].each do |i|

document.each do |line|
  line=line.split(/\b/)
  left=0
  right=line.length
  until left==right do
    test2(line, left, right)
  end
end


# puts document.inspect

files.each do |file|
  line=""
  position=0
  document.split(/\b/).each do |word|
    position=position+1
    puts word.inspect
    if word == "\n" then line="" end
    line=line+word
    if file == line then
      puts "matched"
      line=""
    end
#     puts f, word
  end
end




  if ( match =~ string ) != nil then
    return $` + replacement + $'
  else



# Regular expressions..
(\[{2}[a-z \.,]*\]{2})
(\[{2}[\w\s\d.,|()_\/\-\\]+\]{2})
(\[\[.*?\]\])
