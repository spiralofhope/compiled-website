# Add anything new that's appeared.  Recursive.
# Do not do this!  I have live website content which should never go into the git repository.  Hmm, well maybe that would be a good idea.. Ok, maybe later.: TODO
\git add .

# This will prompt for a comment.
# The editor that is summoned can be customized with:
#   git config --global core.editor <editor>
# See also $EDITOR
\git commit

# git commit -m ''

\git push -u origin master
# \git push -u git@github.com:spiralofhope/compiled-website.git

:<<'heredoc'
http://help.github.com/git-cheat-sheets/

Creating a new tag and pushing it to the remote branch:

  \git tag "v1.3"
  \git push --tags

heredoc
