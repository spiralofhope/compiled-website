#!/bin/env sh

# FIXME: I should already have the daemon running.  So I need to somehow make sure that this stuff here is taking over that lockfile or .. something.

# If I get a file deletion error, manually kill the ruby process.. then re-save compiled_website.rb and things should work out..

# ---

# TODO: Sanity-check on the working directory?
\cd ../../
working=`\pwd`

# new hotness, but it doesn't work.
# working=/c
# cd $working

# ---

/home/user/bin/firefox/firefox \
        -new-tab "file://$working/live/compiled-website-to-do.html" \
        -new-tab "file://$working/live/compiled-website-bugs.html" \
        -new-tab "file://$working/live/sandbox.html" \
        -new-tab "file://$working/live/index.html" &
#links -g ...
#midori &
#netsurf &

# I can't start autotest first and then load this stuff into that very-previous instance.  It'll open in the very first instance of geany.  Sigh.
\geany --new-instance \
  "git/CHANGELOG" \
  "compiled-website.txt" \
  "live/css/common.css" \
  "git/rb/header_and_footer.rb" \
  "git/rb/lib/lib_main.rb" \
  "src/w/compiled-website-to-do.asc" \
  "src/w/compiled-website-bugs.asc" \
  "src/w/sandbox.asc" \
  "git/rb/tests/tc_main.rb" \
  "git/CHANGELOG" \
  &

#\geany \
  #"CHANGELOG" \
  #&

  #"$lib/mine/lib_misc.rb" \

# TODO:  My autotest script is still to be prepared and made public.
/home/user/bin/autotest.sh "$working/git/rb/main.rb" --nodebug

# TODO:  Kill the ruby pid on exit.
# It's not the pid of autotest.sh, it has to be determine from the /tmp pid files.

\cd $working
\cp --force  src/w/compiled-website-demo.asc ./git/examples/demo.asc
\cp --force live/compiled-website-demo.html  ./git/examples/demo.html
