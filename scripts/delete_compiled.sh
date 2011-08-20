working='/mnt/ssd/projects/compiled-website/live/'

# Doesn't remove any .html files in a directory which has 'hosted' in its name.  It's a bit inexact but should be ok.
\find $working \
  ` # This still doesn't seem right.. ` \
  -name 'hosted' -prune -o \
  ` # Umm, isn't this wrong? ` \
  -name 'h' -prune -o \
  -name '*.html' -type f \
  -exec \rm --verbose {} \;
