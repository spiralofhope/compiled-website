
  def header_and_footer(string, source_directory, source_file_full_path, type)
    if $toc == [] then $toc = '' end
    a=Pathname.new(source_directory)
    b=Pathname.new(File.dirname(source_file_full_path))
    path=a.relative_path_from(b)
    puts path.inspect
    sitemap_path=path
    case type
      when 'wiki' then
      when 'blog' then
        path='../' + path
      else
        puts "eek!"
    end
    header_search = Regexp.new('')
    # HTML5 will change the text/html charset definition thusly:
    #<meta charset="UTF-8">
    header_replace=<<-"HEREDOC"
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
<link rel="icon" href="#{path}/i/favicon.ico" type="image/x-icon">
<link rel="shortcut icon" href="#{path}/i/favicon.ico" type="image/x-icon">
<link type="text/css" href="#{path}/css/common.css" rel="stylesheet">
<link type="text/css" href="#{path}/css/default.css"    rel="stylesheet"           title="Default">
<link type="text/css" href="#{path}/css/dark.css"       rel="alternate stylesheet" title="Dark">
<link type="text/css" href="#{path}/css/no-style.css"   rel="alternate stylesheet" title="No Style">
<link type="text/css" href="#{path}/css/test.css"   rel="alternate stylesheet" title="Test">
<title>#{File.basename(source_file_full_path, '.asc')}</title>
<script type="text/javascript" src="#{path}/js/styleswitcher.js">
</script>
<script type="text/javascript"><!--
  function toggle(targetId) {
    target = document.getElementById(targetId);
    if (target.style.display == ""){
      target.style.display="inline";
    } else if (target.style.display == "none"){
      target.style.display="inline";
    } else {
      target.style.display="none";
    }
  }
//--></script>
</head>

<body>
<div class="header">
  <div class="float-left">
    <div class="top-t0">
      <a accesskey="z" href="#{path}/index.html">
        <img alt="spiralofhope logo" src="#{path}/i/spiralofhope-96.png">
      </a>
      <br>
      <div class="top-t1">S</div> <div class="top-t2">piral of Hope</div>
      <div class="top-t3">Better software is possible.</div>
    </div>
  </div>
  <div class="float-right">

<FORM METHOD=POST ACTION="http://www.scroogle.org/cgi-bin/nbbw.cgi">
<INPUT type=text name="Gw" SIZE="25" MAXLENGTH="225" accesskey="f" value="Search">
<INPUT type=hidden name="n" value="2">
<INPUT type=hidden name="d" value="spiralofhope.com" CHECKED>
</FORM></center>
<!--
TODO: RSS
rss-feed-icon-16px-svg.png
-->
    <small>
      <a href="#{path}/javascript.html#s0" onClick="javascript:toggle('styles');return false">Styles</a>
    </small>
    <div id="styles" style="display: none">
      <small>
        <br>
        <a href="#" accesskey="1" onclick="setActiveStyleSheet('Default');  return false;">Default</a>
        |
        <a href="#" accesskey="2" onclick="setActiveStyleSheet('Dark');     return false;">Dark</a>
        |
        <a href="#" accesskey="3" onclick="setActiveStyleSheet('No Style'); return false;">No Style</a>
        |
        <a href="#" accesskey="4" onclick="setActiveStyleSheet('Test'); return false;">Test</a>
        |
        <a href="greasemonkey-and-stylish.html">Your Own!</a>
      </small>
    </div>
    <br>
    <small>
      <a accesskey="t" href="#{path}/javascript.html#s0" onClick="javascript:toggle('toc');return false">Table of Contents</a>
    </small>
    <div class="toc" id="toc" style="display: none">
      #{$toc}
    </div>
  </div>
</div>
<div class="main" id="s0">
<p class="p0">
    HEREDOC
# TODO: The opening <p> I have up here seems a bit off to me.  I don't think I'm appropriately closing it.  But leveraging #{$paragraph = '<!----></div>'} doesn't seem to be the answer!  Damn.

=begin
I simplified it, here's the original:
<form method="get" action="http://www.google.com/search">
<input type="text" name="q" size="25" maxlength="255" accesskey="f" value="Search" />
<input type="submit" value="Search" />
<input type="hidden" name="sitesearch" value="spiralofhope.com" />
=end
    # '~~~~FOOTER~~~~' is a totally hackish thing for me to do, but oh well.
    # Could I search for the EOF or something cool?  Or just.. directly append this to do the bottom perhaps.
    footer_search=Regexp.new('~~~~FOOTER~~~~')
    puts footer_search
    # The top </div> will close any remaining <h1 class="indent1"> type references.  HTML Tidy will clean things up if there are no headers on that page.
    # Close the div created by the last header, if there was one.
    if $toc != '' then
      footer_replace = '</div>'
    else
      footer_replace = ''
    end
    $paragraph||=''
    footer_replace += $paragraph
=begin
It's wasteful to have a duplicate table of contents at the bottom.. it's for people who have JavaScript disabled.
=end
    footer_replace+=<<-"HEREDOC"
    </div> <!-- main -->
      <div class="footer">
        &copy; <a href="#{path}/contact.html#s0">Spiral of Hope</a> - all rights reserved (until I figure licensing out)
        <br>
        <!-- TODO -->
        Hosting provided by (FIXME), <a href="#{path}/thanks.html#s0">thanks!</a>
        <br>
        <em><small>(<a href="#{sitemap_path}/sitemap.html">sitemap</a>)</small></em>
        <br>

#{
# This was some experimentation..
=begin
<script type="text/javascript"><!--
// nothing
//--></script>
<noscript>
<br>
<a id="toc">
Table of Contents
#{$toc}
</noscript>
=end
}
      <a style="display: none;" accesskey="e" href="file://#{source_file_full_path}">&nbsp;</a>
    </div> <!-- footer -->
    <div id="statcounter_image"
    style="display:inline;"><a title="web stats"
    class="statcounter"
    href="http://www.statcounter.com/free_web_stats.html"><img
    src="#{path}/i/statcounter.com-button2.gif"
    alt="web stats"
    style="border:none;"/></a></div>
  </body>
</html>
HEREDOC

    string=multiline_replace(header_search, string, header_replace)
    string=multiline_replace(footer_search, string, footer_replace)
    return string
  end
