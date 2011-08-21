#!/bin/env sh

:<<'heredoc'
This script deletes all the compiled .html files.

That deletion is detected by the compiled website engine, which will
then walk through all source .asc files and rebuild the .html files.

This is important for major events like:

  - Templating changes.

  - A new document needs to be immediately auto-linked within all
    existing documents.

This need is probably the biggest downside to this kind of engine.
heredoc

__FILE__=$( \readlink -f $0 )
working=$( \dirname $__FILE__ )/../../live/
echo $working

# Doesn't remove any .html files in a directory which has 'hosted' in its name.  It's a bit inexact but should be ok.
\find $working \
  ` # This still doesn't seem right.. ` \
  -name 'hosted' -prune -o \
  ` # Umm, isn't this wrong? ` \
  -name 'h' -prune -o \
  -name '*.html' -type f \
  -exec \rm --verbose {} \;
