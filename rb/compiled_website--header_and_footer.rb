# This needs to be overhauled from all sorts of angles.. but it's "working" right now.
# TODO:  Make this more universal.  Extract stuff specific to me and make such things into variables.

# used in header_and_footer()
# require 'pathname'


class Markup
  def header_and_footer( string, source_file_full_path, target_file_full_path, type='wiki' )
#    source_directory = File.dirname( File.realdirpath( source_file_full_path ) )

    # HTML5 will change the text/html charset definition thusly:
    #<meta charset="UTF-8">
    path = File.dirname( File.realdirpath( target_file_full_path ) )
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
            <a accesskey="t" href="javascript.html#s0" onClick="javascript:toggle('toc');return false">Table of Contents</a>
          </small>
          <div class="toc" id="toc" style="display: none">
            #{'TABLE OF CONTENTS TODO'}
          </div>
        </div>
      </div>
      <div class="main" id="s0">
      <p class="p0">
    heredoc

    footer = <<-heredoc.unindent
      </div> <!-- main -->
        <div class="footer">
          &copy; <a href="contact.html#s0">Spiral of Hope</a> - all rights reserved (until I figure licensing out)
          <br>
          <!-- TODO -->
          Hosting provided by (FIXME), <a href="thanks.html#s0">thanks!</a>
          <br>
          <em><small>(<a href="#{sitemap_path}/sitemap.html">sitemap</a>)</small></em>
          <br>
            <a style="display: none;" accesskey="e" href="file://#{source_file_full_path}">&nbsp;</a>
          </div> <!-- footer -->
          <div id="statcounter_image"
          style="display:inline;"><a title="web stats"
          class="statcounter"
          href="http://www.statcounter.com/free_web_stats.html"><img
          src="i/statcounter.com-button2.gif"
          alt="web stats"
          style="border:none;"/></a></div>
        </body>
      </html>
    heredoc

    return header + string + footer
  end
end
