base=/home/user/soh
website=$base/httpdocs
source=$base/source
templates=$base/templates

cd source
echo working ..

# I need a simple "global" command  =(
# For every directory...
for file_source in *.t2t ; do
  file_dest=$website/`basename $file_source .t2t`.htm
  echo working on $file_source
  # dump the header template in
  cp -f $templates/header $file_dest
  cat $file_source >> $file_dest
  # append the footer template (should be $file_sourcename)
  cat $templates/footer >> $file_dest
  # convert the text elements of the file into html
  txt2tags -t html $file_dest
done

echo ""
echo finished...
