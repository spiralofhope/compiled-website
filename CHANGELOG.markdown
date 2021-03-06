  
  * scripts/push_content_to_website.rb
  Added my helper script to sync the website to a server.  More work
  has to be done to make this more universally useful to other people.
  
  * scripts/edit.sh
  Added my helper script to launch and edit this project.  More work
  has to be done to make this more universally useful to other people.
  
  * Beginning to modify my scripts to use a .ini file to load up
  private variables.  This lets me include those scripts into this
  project without having, for example, my directory preferences or
  server password in a script.
  
  * Split up some library code and test cases into separate files.
  This will reduce the complexity of test cases which are important to
  the project versus tried-and-true code.
  
  * String processing can be made faster, I've heard:
    slow:    "string" <<      "string"
    better:  "string" +=      "string"
    best:    "string".concat( "string" )

  * examples/demo.html
    examples/demo.asc
  Added my examples into the projects.  Did some tweaking to make
  sure everything is synced from my live website.
    - I'm not going to add the bugs list, because it is supposed to be
      migrated into test cases.
    - The TODO list needs some major work before some version of it can
      be included in the repository.
  
  * Moved some files around, for better organization.
  
  * Removed the style experimentation stuff.  It'll be archived in 
  1.2.5 and previous.
  
  * Did the work to import all previous revisions and side-experiments
  into the new git repository.  Happy _why day!

2011-08-19  spiralofhope  <spiralofhope@lavabit.com>
  
  1.2.7
  
  * I made a git repo and I'm using github:
  https://github.com/spiralofhope/compiled-website
  
  * Tidied up test cases by using assert_equal_array()
  
  * Any method with more than one parameter has had its parameters 
  reformatted for clarity.  And to punish me for using multiple 
  parameters.  =)
  
  * Renamed the main .rb files.

2011-08-18  spiralofhope  <spiralofhope@lavabit.com>

  1.2.5
  Bumping up the version because too much time has passed.

2011-08-13  spiralofhope  <spiralofhope@lavabit.com>

  1.2.3
  Shit, I forgot to maintain this changelog.. again.
  
  * Very rough rework of not_in_html() with more functionality and 
  intelligence, and hopefully speed.  This might be the key to solving 
  speed issues with links_automatic()
  
  * Added syntax highlighting:
  http://alexgorbatchev.com/SyntaxHighlighter/
  
  * Implemented some hacky functionality to use the full functionality 
  of the syntax highlighting.
  
  * The user can now create their own custom <pre foo="bar"> blocks.  
  Just indent that opening pre.  The ending </pre> is optional.
  
  * hacked js/sh/scripts/shBrushBash.js
    Brush.aliases	= ['bash', 'shell'];
    =>
    Brush.aliases	= ['bash', 'shell', 'sh', 'zsh'];

2011-05-16  spiralofhope  <spiralofhope@lavabit.com>
  
  1.2.2
  
  * I pushed some code into separate files to begin a broader cleanup.
  
  * Removed all of the `old-*` code from the previous generation and 
  experimentation.  It's all still kept "around" in previous versions. 
  Maybe I'll refer back to it all.  Maybe I won't.
  
  * Paragraphs now respect HTML.
  
  * Blocks now respect HTML.  No more odd pre blocks appearing when you
  indent HTML.
  
  * Blocks now have the correct number of spaces within them.
  
  * Markup won't work around named or automatic links.  This is working
  as currently-intended, but I'll have to change the code to support it.
  
  * I'm still finding some strange bugs.  =(

2011-05-15  spiralofhope  <spiralofhope@lavabit.com>
  
  1.2.0
  Squashed a bunch of bugs, rewrote a bunch of code.
  
  * Untangled all the mess and got test cases working well again.  
  Rewrote most of them.
  
  * Got everything to a reasonable state.  There are still some bugs, 
  especially with lists being processed within pre-blocks, but I'll fix 
  that shortly.

2011-05-11  spiralofhope  <spiralofhope@lavabit.com>
  
  1.0.10
  Bumped again, to just go through and chop it apart until it works.
  
  * I finally figured out the nested html stuff.  I'm bumping the 
  version to make it safe to hack around and fix everything.  I've 
  completely smashed everything apart and I need to rebuild everything 
  from the pieces I left behind.

2011-05-22  spiralofhope  <spiralofhope@lavabit.com>
  
  1.0.7
  
  * The previous version represents a massive rewrite.  However, after 
  having gone through a couple of revisions of ideas it has become 
  extremely messy.  Everything is good, and there are ideas in there 
  which fix most of the issues I was having.  To get it fixed up, i'm 
  copying it out into this version and then gutting it and redoing it 
  with my most recent ideas.
  
  * Did some playing with my string matching stuff, but some earlier 
  work is better.  I'm bumping the revision to save this work but I'm 
  going to go back to earlier stuff which could handle nested matches 
  like 'before <><>one</>two</> after'.

2011-05-20  spiralofhope  <spiralofhope@lavabit.com>
  
  1.0.5
  Massive rewrite.  Messy.
  
  * Rewrote paragraphs

  * Rewrote horizontal rules

  * Rewrote plain, named, numbered, automatic local and new local links.
  Automatic local and new local links needed to have test cases that 
  touch the disk.  Those test cases might cause issues on non-Linux and
   needs some more testing.  =(  Ugh, tests that need testing.

  * Lists were rewritten from scratch .. maybe four times.
  Still working on lists of mixed-type.

  * Starting a list of corner-cases or missing test cases / bugs I 
  found.

  * Rewrote <pre> blocks.

2011-04-06  spiralofhope  <spiralofhope@lavabit.com>
  
  1.0.4

  * Moved more code over, and corrected the formatting of it.

  * Just using the new markup_everything() for now, but it works!

  * Included a bunch of my library methods.
  I'll end up pushing it all back out into one or more library files,
  but they'll be specific to this project instead of being outside 
  files as before.

2011-04-01  spiralofhope  <spiralofhope@lavabit.com>
  
  1.0.1_internal
  This entry also had a lot of lingering old stuff that I am probably
  re-introducing to git.
  
  * Copied the core stuff over from 0.8.21.
  
  * Renamed a lot of old stuff.
  
  * Changed the directory structure.  Renamed and moved stuff around.
  
  * Merged all of the `live/common/hosted` into `live/common/h`.
  I'm breaking a few links, but I don't care.

2011-04-01  spiralofhope  <spiralofhope@lavabit.com>
  
  1.0.0_internal
  A complete rewrite.  Presently not functional, but the challenging
  core components have been completed.  Many revisions of my
  experimentation have been left here.
  
  This version only had a slew of markup_experimentation--0.8.21.rb
  files, all with revision numbers.  I'll add them into git.

2011-03-04  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.21_internal
  
  * Ported to Ruby 1.9.2.  Still compatible with 1.8.7.
  It was a simple change with my use of the `result` variable and
  arrays.

2011-03-02  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.19_internal
  
  * Pre-CHANGELOG
  
  * rb/header-and-footer.rb:  First appearance.

2010-11-20  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.17_internal
  
  * Pre-CHANGELOG

2010-05-24  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.16_internal
  
  * Pre-CHANGELOG

2010-05-21  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.14_internal
  
  * Pre-CHANGELOG

2010-05-10  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.12_internal
  
  * Pre-CHANGELOG

2010-05-03  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.10_internal
  
  * Pre-CHANGELOG

2010-05-03  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.8_internal
  
  * Pre-CHANGELOG

2010-05-01  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.6_internal
  
  * Pre-CHANGELOG

2010-05-01  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.4_internal
  
  * Pre-CHANGELOG

2010-04-29  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.3_internal
  
  * Pre-CHANGELOG

2010-04-29  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.2_internal
  
  * Pre-CHANGELOG

2010-04-28  spiralofhope  <spiralofhope@lavabit.com>
  
  0.8.0_internal
  
  * Pre-CHANGELOG

2010-04-27  spiralofhope  <spiralofhope@lavabit.com>
  
  0.7.2_internal
  
  * Pre-CHANGELOG

2010-04-27  spiralofhope  <spiralofhope@lavabit.com>
  
  0.7.0_internal
  
  * Pre-CHANGELOG

2010-04-17  spiralofhope  <spiralofhope@lavabit.com>
  
  0.6.7_internal
  
  * Pre-CHANGELOG

2010-04-16  spiralofhope  <spiralofhope@lavabit.com>
  
  0.6.6_internal
  
  * Pre-CHANGELOG

2010-04-16  spiralofhope  <spiralofhope@lavabit.com>
  
  0.6.4_internal
  
  * Pre-CHANGELOG

2010-04-15  spiralofhope  <spiralofhope@lavabit.com>
  
  0.6.2_internal
  
  * Pre-CHANGELOG

2010-04-15  spiralofhope  <spiralofhope@lavabit.com>
  
  0.6.0_internal
  
  * Pre-CHANGELOG

2010-04-14  spiralofhope  <spiralofhope@lavabit.com>
  
  0.5.8_internal
  
  * Pre-CHANGELOG
  
  * old_lists_experimentation.rb:  First appearance.

2010-04-14  spiralofhope  <spiralofhope@lavabit.com>
  
  0.5.6_internal
  This one introduces CSS, which I will not add to git.  At some future
  point I will create some kind of default theme/templating which can
  then be tracked in the repository.
  
  * Pre-CHANGELOG

2010-01-31  spiralofhope  <spiralofhope@lavabit.com>
  
  0.5.4_internal
  This one seems to work well now, but I had pulled the templating
  (header/footer) functionality to simplify and redo things.
  So that separate code needs to be re-integrated and re-tested.
  
  * Pre-CHANGELOG

2010-01-31  spiralofhope  <spiralofhope@lavabit.com>
  
  0.5.1_internal
  
  * Pre-CHANGELOG
  
  * Began work on a rewrite.

  * This version introduces symbolic links to my libraries.  I'm not
  going to include add the links or the libraries into git, for
  simplicity.  The proper libraries will appear in later revisions,
  when they are no longer merely symbolic links.

2009-04-13  spiralofhope  <spiralofhope@lavabit.com>
  
  0.4.8_internal
  
  * Pre-CHANGELOG
  
  * rb/automated-linking.rb:  First appearance.

2009-07-09  spiralofhope  <spiralofhope@lavabit.com>
  
  0.4.6_internal
  Copied the libraries into the project.
  
  * Pre-CHANGELOG

2009-07-08  spiralofhope  <spiralofhope@lavabit.com>
  
  0.4.4_internal
  This version was the first to see actual live use.
  
  * Pre-CHANGELOG

2009-07-05  spiralofhope  <spiralofhope@lavabit.com>
  
  0.4.0_internal
  
  * Pre-CHANGELOG

2009-07-05  spiralofhope  <spiralofhope@lavabit.com>
  
  0.3.4_internal
  
  * Pre-CHANGELOG

2009-07-04  spiralofhope  <spiralofhope@lavabit.com>
  
  0.3.2_internal
  
  * Pre-CHANGELOG

2009-07-04  spiralofhope  <spiralofhope@lavabit.com>
  
  0.3.0_internal
  
  * Pre-CHANGELOG

2009-07-01  spiralofhope  <spiralofhope@lavabit.com>
  
  0.2.0_internal
  
  * Pre-CHANGELOG

2009-07-01  spiralofhope  <spiralofhope@lavabit.com>
  
  0.0.6_internal
  
  * This was before I maintained this CHANGELOG, so the code changes
  will have to speak for themselves.

2008-08-27  spiralofhope  <spiralofhope@lavabit.com>
  
  0.0.4_internal
  
  * First ruby implementation.
  
  * Removed txt2tags experimentation.

2008-08-27  spiralofhope  <spiralofhope@lavabit.com>
  
  0.0.1_internal
  This was my first experimentation.
  
  * I went from my own hackish stuff to using txt2tags.
  I still had to play with txt2tags to make it sane.
  
  * I don't even know where my first hackish stuff went.  It's
  probably archived in my projects/programming/ somewhere.
  
  * I'm not sure what I'm doing for this changelog, so I'll refer to:
  http://www.gnu.org/prep/standards/html_node/Change-Logs.html
  http://www.gnu.org/software/guile/changelogs/guile-changelogs_3.html
