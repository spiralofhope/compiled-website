# For each of the items in a file, delete the file

$SOH="/mnt/mnt/httpdocs"

def nuke_it(file)
  output_where = "top"
  File.open(file, 'r').each { |line|
    filename = File.join($SOH,"",line)
    # I can't do an "if exists" properly, oh well.
    exec "rm -f " + filename
  }
end

nuke_it("rsync.txt")
