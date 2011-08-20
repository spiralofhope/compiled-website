# Doesn't remove any .html files in a directory which has 'hosted' in its name.  It's a bit inexact but should be ok.
find ../live/ \
  -name 'hosted' -prune -o \
  -name 'h' -prune -o \
  -name '*.html' -type f \
  -exec \rm --verbose {} \;
