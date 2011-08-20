# This needs to be overhauled from all sorts of angles.. but it's "working" right now.
# TODO:  Make this more universal.  Extract stuff specific to me and make such things into variables.

# used in header_and_footer()
# require 'pathname'


class Markup
  def header_and_footer(
                          string,
                          source_file_full_path,
                          target_file_full_path,
                          type='wiki'
                        )
#    source_directory = File.dirname( File.realdirpath( source_file_full_path ) )

    # HTML5 will change the text/html charset definition thusly:
    #<meta charset="UTF-8">
    #path = File.dirname( File.realdirpath( target_file_full_path ) )
    path = File.dirname( target_file_full_path )
    sitemap_path = 'TODO'
    
    header = <<-heredoc.unindent
      <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
      <html>
      <head>
      <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
      <link rel="icon" href="i/favicon.ico" type="image/x-icon">
      <link rel="shortcut icon" href="i/favicon.ico" type="image/x-icon">
      <link type="text/css" href="css/common.css"     rel="stylesheet">
      <link type="text/css" href="css/default.css"    rel="stylesheet"           title="Default">
<!--
      <link type="text/css" href="css/default.css"    rel="stylesheet"           title="Default">
-->
      <link type="text/css" href="css/dark.css"       rel="alternate stylesheet" title="Dark">
      <link type="text/css" href="css/no-style.css"   rel="alternate stylesheet" title="No Style">
      <link type="text/css" href="css/test.css"       rel="alternate stylesheet" title="Test">
      <title>#{File.basename(source_file_full_path, '.asc')}</title>
      <script type="text/javascript" src="js/styleswitcher.js">
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
<script type="text/javascript" src="js/sh/scripts/shCore.js"></script>
<script type="text/javascript" src="js/sh/scripts/shAutoloader.js"></script>
      </head>
      
      <body>
      <div class="header">
        <div class="float-left">
          <div class="top-t0">
            <a accesskey="z" href="index.html">
              <div class="logo_default">
                <img alt="spiralofhope logo" src="i/spiralofhope-96-default.png">
              </div>
              <div class="logo_dark">
                <img alt="spiralofhope logo" src="i/spiralofhope-96-dark.png">
              </div>
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
            <a href="javascript.html#s0" onClick="javascript:toggle('styles');return false">Styles</a>
          </small>
          <div id="styles" style="display: none">
            <small>
              <br>
              <a href="#" accesskey="8" onclick="setActiveStyleSheet('Default');  return false;">Default</a>
              |
              <a href="#" accesskey="9" onclick="setActiveStyleSheet('Dark');     return false;">Dark</a>
              |
              <a href="#" accesskey="0" onclick="setActiveStyleSheet('No Style'); return false;">No Style</a>
              |
              <a href="#" onclick="setActiveStyleSheet('Test'); return false;">Test</a>
              |
              <a href="greasemonkey-and-stylish.html">Your Own!</a>
            </small>
          </div>
          <br>
          <small>
            <a accesskey="t" href="javascript.html#s0" onClick="javascript:toggle('toc');return false">Table of Contents</a>
          </small>
          <div class="toc" id="toc" style="display: none">
            #{'TODO'}
          </div>
        </div>
      </div>
      <div class="main" id="s0">
      <p class="p0">
    heredoc

    footer = <<-heredoc.unindent
      </div> <!-- main -->
        <div class="footer">
<a href="about-me.html">About Me</a> | <a href="contact-me.html">Contact Me</a>
<center>
<table width="80%">
<tr>
<td width="50%">
  <small>
  &copy; <a href="contact.html#s0">spiralofhope.com</a>, all rights reserved.
  <br>
  Individual pages or files may have their own copyright / licensing.
  </small>
</td>
<td width="50%">
<small>
  <a href="http://www.dreamhost.com/r.cgi?1159806/green.cgi?spiralofhope.com|SPIRALOFHOPE">
    <img border="0" alt="Green Web Hosting!" src="i/dreamhost--green1.gif" height="32" width="100" />
  </a>
  <a href="http://www.dreamhost.com/donate.cgi?id=14842">
    <img border="0" alt="If you've found this website useful, donate towards my web hosting bill." src="i/dreamhost--donate1.gif" />
  </a>
  <br>
  <a href="http://www.dreamhost.com/r.cgi?1159806/signup">
    <u>DreamHost - Unlimited space and bandwidth.</u>
  </a>
  <br>
  As low as $8.95/mo.
  <br>
  $40 discount with the promo code SPIRALOFHOPE
</small>
</td>
</tr>
</table>
</center>

<!-- TODO
          <br>
          <em><small>(<a href="#{sitemap_path}/sitemap.html">sitemap</a>)</small></em>
          <br>
-->
          <a style="display: none;" accesskey="e" href="file://#{source_file_full_path}">&nbsp;</a>
          </div> <!-- footer -->

<!-- Start of StatCounter Code for Default Guide -->
<script type="text/javascript">
var sc_project=4910069; 
var sc_invisible=0; 
var sc_security="1ce5ea53"; 
</script>
<script type="text/javascript"
src="http://www.statcounter.com/counter/counter.js"></script>
<noscript><div class="statcounter"><a title="tumblr
statistics" href="http://statcounter.com/tumblr/"
target="_blank"><img class="statcounter"
src="http://c.statcounter.com/4910069/0/1ce5ea53/0/"
alt="tumblr statistics"></a></div></noscript>
<!-- End of StatCounter Code for Default Guide -->

        </body>

<script type="text/javascript">
function path()
{
  var args = arguments,
      result = []
      ;
       
  for(var i = 0; i < args.length; i++)
      result.push(args[i].replace('@', 'js/sh/scripts/'));
       
  return result
};
 SyntaxHighlighter.autoloader.apply(null, path(
  'applescript            @shBrushAppleScript.js',
  'actionscript3 as3      @shBrushAS3.js',
  'bash shell sh zsh      @shBrushBash.js',
  'coldfusion cf          @shBrushColdFusion.js',
  'cpp c                  @shBrushCpp.js',
  'c# c-sharp csharp      @shBrushCSharp.js',
  'css                    @shBrushCss.js',
  'delphi pascal          @shBrushDelphi.js',
  'diff patch pas         @shBrushDiff.js',
  'erl erlang             @shBrushErlang.js',
  'groovy                 @shBrushGroovy.js',
  'java                   @shBrushJava.js',
  'jfx javafx             @shBrushJavaFX.js',
  'js jscript javascript  @shBrushJScript.js',
  'perl pl                @shBrushPerl.js',
  'php                    @shBrushPhp.js',
  'text plain             @shBrushPlain.js',
  'py python              @shBrushPython.js',
  'ruby rails ror rb      @shBrushRuby.js',
  'sass scss              @shBrushSass.js',
  'scala                  @shBrushScala.js',
  'sql                    @shBrushSql.js',
  'vb vbnet               @shBrushVb.js',
  'xml xhtml xslt html    @shBrushXml.js',
  'lua                    @shBrushLua.js'
)); 
SyntaxHighlighter.all();
</script>
      </html>
    heredoc

    return header + string + footer
  end
end
