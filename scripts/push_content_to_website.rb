#!/bin/env sh

__FILE__=$( \readlink -f $0 )
working=$( \dirname $__FILE__ )

\. $working/../../compiled-website.ini
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

\lftp -c "
  ` # TLS/SSL is automatically negotiated if supported by the server. ` \
  open -u $user,$pass $sftp$server$directory ;\
  mirror --reverse --delete --parallel=2 --verbose --ignore-time ;\
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
  __FILE__=$( \readlink -f $0 )
  \. ./compiled-website.ini
  \lftp -e "open -u $user,$pass $sftp$server$directory"

- Files are not found when surfing to them with a browser.
-- FTP in manually and `chmod a+x` the directories.
heredoc
