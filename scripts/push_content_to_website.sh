#!/bin/sh

# IMPORTANT TODO:
# chmod -R o+r spiralofhope.com ; chmod -R g+r spiralofhope.com

# --
# Read in the .ini
__FILE__=$( \readlink -f $0 )
working=$( \dirname $__FILE__ )
\. $working/../../compiled-website.ini
# --

echo $pass

working=$working/../..
\cd $working/live

# --
# Push the changes to the website
# --
\echo " * Pushing changes to the website.."
# It's unfortunate that this doesn't give a summary.  Oh well.
#\lftp -c "
#  open -u $user,$pass $server ;\
#  mirror --reverse --delete --parallel=2 --verbose --ignore-time ;\
#  "

# I don't think I need to do this, since I have the right parameters for mirror now.
# set mirror:set-permissions false ;\
# If the  mirror:set-permissions  isn't working, then do this:
#` # Fix permissions (group, then other) ` \
#chmod -R g+r . ;\
#chmod -R o+r . ;\

\lftp -c "
  ` # TLS/SSL is automatically negotiated if supported by the server. ` \
  open \
    -u $user,\"$pass\" \
    $sftp$server$directory \
    ;\
  ` # Push content TO the server. ` \
  mirror \
    --continue \
    --delete \
    ` # Symbolic links are sent as their source file. ` \
    --dereference \
    --ignore-time \
    --no-perms \
    --no-umask \
    --parallel=2 \
    --reverse \
    --verbose \
    ;\
  "

: <<'heredoc'
\echo " * Generating a new sitemap.xml.."
\python "working/sitemap_gen.py \
  --block asc \
  --output-file sitemap.xml \
  http://spiralofhope.com/sitemap.html

\echo " * Pushing changes to the website"
\echo " * .. again, to send the new sitemap.xml.."
\lftp -c "
  open -u $user,$pass $server ;\
  mirror --reverse --continue --delete --parallel=2 --verbose ;\
  "
heredoc

#curlftpfs-root -f -d -o allow_other -o user="USERNAME:PASSWORD" HOST /mnt/ftp&

: <<'heredoc'
= Website Troubleshooting =

- Manually SFTP in:

  \. ./compiled-website.ini
  \lftp -e "open -u $user,\"$pass\" $sftp$server$directory"

- Files are not found when surfing to them with a browser.
-- FTP in manually and `chmod a+x` the directories.
heredoc
