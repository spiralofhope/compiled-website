def multiline_replace(match, string, replacement)
  if ( match =~ string ) != nil then
    return $` + replacement + $'
  else
    return string
  end
end
def test_multiline_replace
  match = Regexp.new('<body>\n\n')

  string = <<END
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>no title (Generated by BlueFeather)</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
<body>

<p>hello world!</p>

<p><em>I am formatted text!</em></p>

</body>
</html>
END

  replacement = <<END
<body>
<!-- header -->
Testing!
<!-- /header -->

END

puts multiline_replace(match, string, replacement)
end
# test_multiline_replace


# mimics 'basename' but works on strings
# File.extname works on strings / extensions, but File.basename does not.  So let's use that..
def string_basename(string)
  return string.sub(File.extname(string),'')
end
# puts string_basename("test.one.two")
#   => "test.one"
# puts string_basename(string_basename("test.one.two"))
#   => "test"

__END__

