SOH=/home/user/soh/httpdocs
RSYNC=$SOH/../rsync.txt
RSYNC2=$SOH/../rsync2.txt

echo " # running rsync --dry-run to get a list of new files"
rsync --dry-run -vrlt $SOH/ /mnt/mnt/httpdocs/ > $RSYNC

echo " # processing the rsync file to remove the header/footer"
# nuke the first line
sed '1d' < $RSYNC > $RSYNC2

# nuke the last three lines
sed -e :a -e '$d;N;2,3ba' -e 'P;D' < $RSYNC2 > $RSYNC

rm $RSYNC2

echo " # Running ruby script to nuke updated files from the remote server"
ruby sync.sh.rb

rm rsync.txt

echo " # Synchronizing new/updated files"
rsync -vrlt --delete $SOH/ /mnt/mnt/httpdocs/

