=begin
- TODO: Implement - for unordered lists, and # for ordered lists
- Consider manual lists.. I count the lines and paint the numbers myself.  This will let me have broken lists like this:

# one
# two
<pre>
something
</pre>
# three
# four

- TODO: Have [http://example.com] type links, which become [1] etc, auto-numbered.
- TODO: A better 'listings' feature.  Just have it output the right CSS and let the user figure out how it ought to be displayed.  I'm tired of ;list: item
- TODO: colon (:) for indentation
- TODO: Manually-indent blocks between headers, like the original coWiki did.  I wonder what the HTML for that was.  Consider looking into my old archives, like my old RPG archives I sent to Angus.
- TODO: implement "new page" creation concepts.  I would make a link like [[link]] and then the system would point me to the appropriate source .asc file.  This would summon my editor as usual, and I can make the page very easily.
- TODO: tables, somehow..
=end


=begin
Requirements:
HTML Tidy
  http://tidy.sourceforge.net/

  cvs -d:pserver:anonymous@tidy.cvs.sourceforge.net:/cvsroot/tidy login
  cvs -z3 -d:pserver:anonymous@tidy.cvs.sourceforge.net:/cvsroot/tidy co -P tidy
  cd tidy/build/gmake
  make
  su
  make install


Notes:
TODO: I'd love to use Ruby/HTML Tidy, but I don't know how to make it go.
  http://tidy.rubyforge.org/
  http://rubyforge.org/projects/tidy
  http://tidy.rubyforge.org/classes/Tidy.html
  gem install tidy
=end

=begin
Usage:
- You can combine multiple markup by starting it all with spaces between them.
- wiki-style linking is done automatically
=end


def marked_yes(string, search_left, search_right, replace_left, replace_right)
  if string == nil then return '' end
  # TODO: If a link, check that the destination exists
  #  - local = create the file
  #  - remote = check if it exists, and cache the results?  Only check once a day?  Then I can redirect to a page if I know the link is bad, and create a notification to myself.. maybe updating a master status log file.
  if replace_left == nil && replace_right == nil then
    return string
  elsif replace_left == nil then
    return string.sub(search_right, replace_right)
  elsif replace_right == nil then
    return string.sub(search_left, replace_left)
  else
    return string.sub(search_left, replace_left).sub(search_right, replace_right)
  end
end

def marked_no(string, internal_markup_flag)
  if string == nil then return '' end
  # TODO: Automatic-linking
  # TODO: My own markup

  if internal_markup_flag != true then
    # TODO: If every regex has the same start and end block, I should somehow be able to remove that duplication.. but I'd have to research regexes more and maybe other stuff.  I'm not sure what to do.
    # TODO: Allow more punctuation on the right side of the search.
    string=chew(string, /(^| )\//, /\/(\.|$)/, '\1<em>', '</em>\1', true)
    string=chew(string, /(^| )\*\*/, /\*\*(\.|$)/, '\1<big>', '</big>\1', true)
    string=chew(string, /(^| )\*/, /\*(\.|$)/, '\1<b>', '</b>\1', true)
    string=chew(string, /(^| )_/, /_(\.|$)/, '\1<u>', '</u>\1', true)
    string=chew(string, /(^| )-/, /-(\.|$)/, '\1<s>', '</s>\1', true)
    string=chew(string, /(^| )((http\:\/\/|ftp:\/\/|irc:\/\/|gopher:\/\/)(.*)(\....?))( |$)/, /( |$)/, '\1<a href="\2">\2</a> ', '\1', true)
    internal_markup_flag=false
  end
  return string
end

# TODO: Either do this per-line, or fix the regex and/or \n so that I can make it a whole-file thing.
def chew(string, search_left, search_right, replace_left, replace_right, internal_markup_flag)
  processed=""
  # This is to avoid a runaway process:
  count=0
  until string == nil or count > 100 do
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

# TODO: get the list of files in the current directory, return it as a simple array.. should be trivial to do.
def get_files()
  return ['some-example.html', 'some.html']
end
# TODO:  Only allow one link for each file?  I'd have to maintain a working array of all the already-created links, and know if I'm creating a duplicate.
# TODO:  Possibly only one link for every header-section.  Somewhat more complex than the above, but really really worth it.
def automatic_linking(files, document)
  document_working=[]
  document.each do |line|
    files.each do |file|
      # 'some-example.html' => 'some example'
      # dashes become spaces
      file_string=file.gsub(/-/, ' ')
      # remove the ending .html
      file_string=file_string.sub(/\.html$/, '')

      file='./' + file
      line=chew(line, /(^| )(#{file_string})( |$)/, //, '\1<a href="' + file + '">\2</a>\3', '', true)
    end
    document_working << line
  end
  return document_working.to_s
end

document=<<-HEREDOC
example code:
*bold* **big** _underline_ /italics/ -strikethrough-
Yes, this is legal in my code.  I'll just clean it up with HTML Tidy.:
  *two _words* test_
< test <> *no markup here* </>
left <a href="http://example.com">no *markup* here</a> right
* _bold underline_ * _ *underline bold* _ _ * / underlined bold emphasis / * _
** * - _ /big bold strikethrough underlined emphasis/_-***
<nowiki>*test*</nowiki>  <anything>_yep_</> <>don't</>
left http://example.com right
http://invalid http://invalid.c
http://valid.ca
http://valid.com
ftp://cool.ca
*bold*._invalid_
this is some example text
this is some text
this is someexample text
this issome example text
HEREDOC

document=automatic_linking(get_files(), document)

# Yes it outputs them with spaces between them, but that's ok for HTML. TODO: Check if tidy will clean that up.  Notice the right side doesn't need spaces, and you can even mash *** together.
document=chew(document, /<.*?>/, /<.*?>/, nil, nil, false)

puts document

# FIXME: tidy isn't installed any more..
# system('tidy -indent -upper -clean -quiet -omit -asxhtml -access -output file', document)







__END__
