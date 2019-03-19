ad_library {

    Tests that deal with the html - text procs

    @creation-date 2017-01-12
}


aa_register_case \
    -cats {web api smoke} \
    -procs {ad_dom_sanitize_html} \
    ad_dom_sanitize_html {

    Test if it HTML sanitization works as expected

} {

    # - Weird HTML, nonexistent and unclosed tags, '<' and '>' chars:
    #   result should be ok, with '<' and '>' converted to entities
    lappend test_msgs "Test case 1: invalid markup with single '<' and '>' chars ok"
    lappend test_cases {<noexist>sadsa</noexist> dfsdafs <a> 3 > 2 dfsdfasdfsdfsad  sasasadsasa <    sadASDSA}
    lappend test_results_trivial {<noexist>sadsa</noexist> dfsdafs <a> 3 &gt; 2 dfsdfasdfsdfsad  sasasadsasa &lt;    sadASDSA</a>}
    lappend test_results_no_js {<noexist>sadsa</noexist> dfsdafs <a> 3 &gt; 2 dfsdfasdfsdfsad  sasasadsasa &lt;    sadASDSA</a>}
    lappend test_results_no_outer_urls {<noexist>sadsa</noexist> dfsdafs <a> 3 &gt; 2 dfsdfasdfsdfsad  sasasadsasa &lt;    sadASDSA</a>}
    lappend test_results_fixing_markup {<noexist>sadsa</noexist> dfsdafs <a> 3 &gt; 2 dfsdfasdfsdfsad  sasasadsasa &lt;    sadASDSA</a>}

    # - Weird HTML, nonexistent and unclosed tags, MULTIPLE '<' and '>' chars:
    #   some loss in translation, multiple '<' and '>' become single ones
    lappend test_msgs "Test case 2: invalid markup with multiple '<' and '>' chars ok"
    lappend test_cases {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 < 2 dfsdfasdfsdfsad <<<<<<<<<< a <<< a << <<< << sasasadsasa <    sadASDSA
    }
    lappend test_results_trivial {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 &lt; 2 dfsdfasdfsdfsad &lt; a &lt; a &lt; sasasadsasa &lt;    sadASDSA
    }
    lappend test_results_no_js {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 &lt; 2 dfsdfasdfsdfsad &lt; a &lt; a &lt; sasasadsasa &lt;    sadASDSA
    }
    lappend test_results_no_outer_urls {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 &lt; 2 dfsdfasdfsdfsad &lt; a &lt; a &lt; sasasadsasa &lt;    sadASDSA
    }
    lappend test_results_fixing_markup {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 &lt; 2 dfsdfasdfsdfsad &lt; a &lt; a &lt; sasasadsasa &lt;    sadASDSA
    }

    # - Half opened HTML into other markup: this markup will be completely rejected
    lappend test_msgs "Test case 3: invalid unparseable markup ok"
    lappend test_cases {
        <noexist>sadsa</noexist> dfsdafs <a><tag</a> 3 sadASDSA
    }
    lappend test_results_trivial {}
    lappend test_results_no_js {}
    lappend test_results_no_outer_urls {}
    lappend test_results_fixing_markup {}

    # - Formally invalid HTML: this markup will be rejected when the
    #   fix option is not enabled and parsed otherwise. Internal
    #   blank space into tags will be lost.
    lappend test_msgs "Test case 4: formally invalid markup ok"
    lappend test_cases {<div a %%> fooo <a>}
    lappend test_results_trivial {}
    lappend test_results_no_js {}
    lappend test_results_no_outer_urls {}
    lappend test_results_fixing_markup "<div a=\"\">fooo<a></a>\n</div>"

    # - Plain text: this should stay as it is
    lappend test_msgs "Test case 5: plain text ok"
    set test_case {
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed
        do eiusmod tempor incididunt ut labore et dolore magna
        aliqua. Ut enim ad minim veniam, quis nostrud exercitation
        ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis
        aute irure dolor in reprehenderit in voluptate velit esse
        cillum dolore eu fugiat nulla pariatur. Excepteur sint
        occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.
    }
    lappend test_cases $test_case
    lappend test_results_trivial $test_case
    lappend test_results_no_js $test_case
    lappend test_results_no_outer_urls $test_case
    lappend test_results_fixing_markup $test_case    

    # Try test cases allowing all kind of markup
    foreach \
        msg          $test_msgs \
        test_case    $test_cases \
        test_result  $test_results_trivial {
            set result [ad_dom_sanitize_html -html $test_case \
                            -allowed_tags * \
                            -allowed_attributes * \
                            -allowed_protocols *]
            set result [string trim $result]
            set test_result [string trim $test_result]
            aa_true "$msg trivial?" {$result eq $test_result}
        }

    # Try test cases not allowing js
    foreach \
        msg          $test_msgs \
        test_case    $test_cases \
        test_result  $test_results_no_js {
            set result [ad_dom_sanitize_html -html $test_case \
                            -allowed_tags * \
                            -allowed_attributes * \
                            -allowed_protocols * \
                            -no_js]
            set result [string trim $result]
            set test_result [string trim $test_result]
            aa_true "$msg no js?" {$result eq $test_result}
        }

    # Try test cases not allowing outer URLs
    foreach \
        msg          $test_msgs \
        test_case    $test_cases \
        test_result  $test_results_no_outer_urls {
            set result [ad_dom_sanitize_html -html $test_case \
                            -allowed_tags * \
                            -allowed_attributes * \
                            -allowed_protocols * \
                            -no_outer_urls]
            set result [string trim $result]
            set test_result [string trim $test_result]
            aa_true "$msg no outer URLs?" {$result eq $test_result}
        }

    # Try test cases fixing markup
    foreach \
        msg          $test_msgs \
        test_case    $test_cases \
        test_result  $test_results_fixing_markup {
            set result [ad_dom_sanitize_html -html $test_case \
                            -allowed_tags * \
                            -allowed_attributes * \
                            -allowed_protocols * \
                            -fix]
            set result [string trim $result]
            set test_result [string trim $test_result]
            aa_true "$msg fixing markup?" {$result eq $test_result}
        }

    # openacs.org landing page source from 2019-04-19
    set testcase {
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
        <html lang="en">
        <head>
        <title>OpenACS Home</title>

        <meta http-equiv="content-style-type" content="text/css">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="description" content="OpenACS is an open source toolkit for building scalable, community-oriented web applications. OpenACS is the foundation for many products and websites, including the .LRN (pronounced &#34;dot learn&#34;) e-learning platform.
">
        <meta http-equiv="content-type" content="text/html; charset=utf-8">
        <meta name="generator" content="OpenACS version 5.10.0d12">
        <link rel="stylesheet" href="/resources/openacs-bootstrap3-theme/css/all.min.css" type="text/css" media="all">
        <script type="text/javascript" src="/resources/openacs-bootstrap3-theme/js/all.min.js" async="async" nonce="AD0268558620334765298A2E8592D3D3D01A7C1A"></script>
        <script type="text/javascript" src="/resources/boomerang/boomerang-1.0.1514200883.min.js" nonce="AD0268558620334765298A2E8592D3D3D01A7C1A"></script>
        <script type="text/javascript" nonce="AD0268558620334765298A2E8592D3D3D01A7C1A">
        BOOMR.init({
            beacon_url: "/boomerang_handler",
            log: null
        });
        </script>

        </head>
        <body>



        <div class="container-fluid">
        <!-- START HEADER -->
        <div class="row header">
        <!-- large icon fo large screens -->
        <div class="col-sm-4 col-md-3 hidden-xs">
        <div class="logo-wrapper"><span class="invisible">logo</span></div>
        <div class="logo">
        <a href="/">

        <img src="/resources/openacs-bootstrap3-theme/images/openacs2.png" alt="Home">

        </a>
        </div>
        </div>

        <div class="col-sm-8 col-md-9" style="padding-right:0;">
        <nav class="navbar navbar-default main-nav">
        <div class="container-fluid">
        <div class="navbar-header">
        <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1" aria-expanded="false">
        <span class="sr-only">Toggle navigation</span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        </button>
        <!--  small icon for xs screens -->
        <span class="hidden-lg hidden-md hidden-sm"><a class="navbar-brand" href="/" style="padding:3px;">

        <img src="/resources/openacs-bootstrap3-theme/images/openacs2_xs.png" alt="Home"></a></span>

        </div>

        <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">

        <div class="block-marker">Begin main navigation</div>
        <ul class="nav navbar-nav navbar-right">

        <!-- main -->

        <li>
        <a href="/about/"
        title="About OpenACS" accesskey="0" tabindex="0">

        <span class="hidden-sm">About</span>
        <span class="hidden-lg hidden-md hidden-xs"><i class="glyphicon glyphicon-info-sign" aria-hidden="true"></i></span>
        </a>
        </li>

        <li>
        <a href="/projects/"
        title="Projects based on OpenACS" accesskey="1" tabindex="1">

        <span class="hidden-sm">Projects</span>
        <span class="hidden-lg hidden-md hidden-xs"><i class="glyphicon glyphicon-blackboard" aria-hidden="true"></i></span>
        </a>
        </li>

        <li>
        <a href="/projects/openacs/download/"
        title="Download OpenACS" accesskey="2" tabindex="2">

        <span class="hidden-sm">Download</span>
        <span class="hidden-lg hidden-md hidden-xs"><i class="glyphicon glyphicon-save" aria-hidden="true"></i></span>
        </a>
        </li>

        <li>
        <a href="/doc/"
        title="OpenACS Core, API and Package Documentation" accesskey="3" tabindex="3">

        <span class="hidden-sm">Documentation</span>
        <span class="hidden-lg hidden-md hidden-xs"><i class="glyphicon glyphicon-file" aria-hidden="true"></i></span>
        </a>
        </li>

        <li>
        <a href="/xowiki/"
        title="Wiki with User Contributed Content" accesskey="4" tabindex="4">

        <span class="hidden-sm">Wiki</span>
        <span class="hidden-lg hidden-md hidden-xs"><i class="glyphicon glyphicon-paperclip" aria-hidden="true"></i></span>
        </a>
        </li>

        <li>
        <a href="/forums/"
        title="OpenACS and DotLRN Discussion Forums" accesskey="5" tabindex="5">

        <span class="hidden-sm">Forums</span>
        <span class="hidden-lg hidden-md hidden-xs"><i class="glyphicon glyphicon-comment" aria-hidden="true"></i></span>
        </a>
        </li>

        <li><a href="/register/?return_url=/">Log In</a></li>


        </ul>

        </div><!-- /.navbar-collapse -->
        </div>
        </nav>
        </div>
        <div class="searchfield">
        <div class="col-xs-12 col-sm-6 col-md-3 col-sm-offset-6 col-md-offset-9 search">
        <form method="GET" action="/search/search" class="form-inline">
        <div class="input-group">
        <input type="text" class="form-control" name="q" title="Enter keywords to search for" maxlength="256" placeholder="Search">
        <input type="hidden" name="__csrf_token" value="013D4454290F720D7D494797B9E9B840BD471481">
        <span class="input-group-btn">
        <button type="submit" class="btn btn-default">Go!</button>
        </span>
        </div>
        </form>
        </div>
        </div>


        </div>
        <!-- END HEADER -->



        <div class="block-marker">Begin main content</div>
        <div class="main-content" style="margin-bottom:100px;">


        <div class="row">
        <div class="col-xs-12 slogan">
        <h1>OpenACS. The Toolkit for Online Communities</h1>
        <div class="subtitle"><div class="statistics">
        20544 Community Members, <a href="/shared/whos-online">2 members online</a>, 1952 visitors today
        </div></div>
        </div>
        </div>

        <div class="row">

        <div class="col-md-6 col-sm-8 col-xs-12 col-md-push-3">
        <div class="news">
        <h2>
        <span class="news-heading">News</span><span class="rss-feed"><a href="/news/rss/rss.xml" title="Subscribe to news via RSS"><img src="/resources/openacs-bootstrap3-theme/images/rss.png" width="30" height="30" alt="Subscribe via RSS" style="border:0"></a></span>
        </h2>


        <div class="news-item">
        <h3 class="item-title">
        <a href="/news/item?item_id=5373786">OpenACS 5.9.1 final released</a>
        </h3>
        <div class="item-content" >We are proud to announce the release of OpenACS 5.9.1.<p>

        This release contains many security and performance improvements and includes new functionalities.

        The release of OpenACS 5.9.1 contains the 88 packages of the oacs-5-9 branch.  These packages include the OpenACS core packages, the major application packages (e.g. most the ones used on OpenACS.org), and DotLRN 2.9.1.

        <ul>

        <li> Refactoring of rich-text editor integration

        </li><li>Improved admin interface (e.g. theme manager), improved scalability for large sites</li><li>Improvements for "host-node mapped" subsites,  acs-rels, status code handlers for AJAX, Internationalization, and documentation.</li>

        </ul>

        </p><p>

        Altogether, OpenACS 5.9.1 differs from OpenACS 5.9.0 in about 312710 line insertions and 103273 deletions, contributed by 5 committers and 8 additional bug-fix submitters. All packages of the release were tested with PostgreSQL 9.6.* and Tcl 8.5.*.

        </p><p>

        Many thanks to all who helped in this effort via direct contributions, bug-reports or testing!

        </p><p>

        <a href="/Announce-OpenACS-5.9.1">Release Announcement</a>,  <a href="/changelogs/ChangeLog-5.9.1">ChangeLog</a>, <a href="http://openacs.org/projects/openacs/download/download/openacs-5.9.1.tar.gz?revision_id=5373766">Download core</a>, <a href="http://openacs.org/projects/openacs/download/download/openacs-5.9.1.tar.gz?revision_id=5373772">Download full</a>

        </p></div>
        <div class="publish-date">Published on Aug 08, 2017  </div>
        </div>

        </div>
        <div class="postings">
        <h2>Recent Announcements</h2>


        <div class="forum">
        <ul class="list-unstyled">
        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5403531">Announcement: NaviServer 4.99.17 available</a></div>
        <div class="posting-date"> Gustaf Neumann, 4 months ago</div>
        </li>
        </ul>
        </div>

        <div class="forum">
        <ul class="list-unstyled">
        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5401789">Announcement: NaviServer module for Web Push</a></div>
        <div class="posting-date"> Gustaf Neumann, 5 months ago</div>
        </li>
        </ul>
        </div>

        <div class="forum">
        <ul class="list-unstyled">
        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5398403">Announcement: improved api-doc with calling information, call-graph and test coverage</a></div>
        <div class="posting-date"> Gustaf Neumann, 7 months ago</div>
        </li>
        </ul>
        </div>

        <div class="forum">
        <ul class="list-unstyled">
        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5397716">ANNOUNCE: tDOM 0.9.1</a></div>
        <div class="posting-date"> Rolf Ade, 7 months ago</div>
        </li>
        </ul>
        </div>

        <div class="forum">
        <ul class="list-unstyled">
        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5390620">Announcement: Measure against password guessing attacks</a></div>
        <div class="posting-date"> Gustaf Neumann, 1 year ago</div>
        </li>
        </ul>
        </div>

        <div class="forum">
        <ul class="list-unstyled">
        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5388591">Annoucement: Support for markdown in richtext widget</a></div>
        <div class="posting-date"> Gustaf Neumann, 1 year ago</div>
        </li>
        </ul>
        </div>

        <div class="forum">
        <ul class="list-unstyled">
        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5387444">Announcement: Boomerang Plugin for OpenACS</a></div>
        <div class="posting-date"> Gustaf Neumann, 1 year ago</div>
        </li>
        </ul>
        </div>

        <div class="forum">
        <ul class="list-unstyled">
        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5386416">ANNOUNCE: NaviServer 4.99.16 available </a></div>
        <div class="posting-date"> Gustaf Neumann, 1 year ago</div>
        </li>
        </ul>
        </div>

        <div class="forum">
        <ul class="list-unstyled">
        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5386140">Announcement: Cookie-Consent Widget</a></div>
        <div class="posting-date"> Gustaf Neumann, 1 year ago</div>
        </li>
        </ul>
        </div>

        <div class="forum">
        <ul class="list-unstyled">
        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5330385">ANNOUNCE: openacs-bootstrap3-theme is available </a></div>
        <div class="posting-date"> Gustaf Neumann, 2 years ago</div>
        </li>
        </ul>
        </div>

        </div>
        </div>

        <div class="col-md-3 col-sm-4 col-xs-12 col-md-push-3">
        <div class="postings">
        <h2>Recent Discussions</h2>


        <div class="forum">
        <h3 class="forum-title">
        <a href="/forums/forum-view?forum_id=14017">.LRN Q&amp;A</a>
        </h3>
        <ul class="list-unstyled">

        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5412579">File Storage Error on Arch Linux</a></div>
        <div class="posting-date"> Antonio Pisano, 1 week ago</div>
        </li>

        </ul>
        </div>

        <div class="forum">
        <h3 class="forum-title">
        <a href="/forums/forum-view?forum_id=14014">OpenACS Development</a>
        </h3>
        <ul class="list-unstyled">

        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5413439">cal_item_new doesn&#39;t exist inside dotlrn</a></div>
        <div class="posting-date"> Gustaf Neumann, 7 hours ago</div>
        </li>

        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5413216">Bug in lang::util::default_ locale_from_lang_not _cached with zh_CN and zh_TW</a></div>
        <div class="posting-date"> Frank Bergmann, 2 days ago</div>
        </li>

        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5413391">To view file in /file-storage/view - ad_html_text_convert able_p</a></div>
        <div class="posting-date"> Gustaf Neumann, 2 days ago</div>
        </li>

        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5412126">Announcement: NaviServer 4.99.18 available</a></div>
        <div class="posting-date"> Michael Aram, 4 days ago</div>
        </li>

        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5412295">HostNode Mapping Vs CSP Violation</a></div>
        <div class="posting-date"> Iuri Sampaio, 2 weeks ago</div>
        </li>

        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=5409380">invalid command name calling clock format</a></div>
        <div class="posting-date"> Gustaf Neumann, 2 weeks ago</div>
        </li>

        </ul>
        </div>

        <div class="forum">
        <h3 class="forum-title">
        <a href="/forums/forum-view?forum_id=14013">OpenACS Q&amp;A</a>
        </h3>
        <ul class="list-unstyled">

        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=185924">ENDEAVOUR International Payment Gateway</a></div>
        <div class="posting-date"> Monica Jenner, 5 hours ago</div>
        </li>

        <li style="clear:both;">
        <div><a href="/forums/message-view?message_id=3854601">providing RESTful apis</a></div>
        <div class="posting-date"> Frank Bergmann, 2 days ago</div>
        </li>

        </ul>
        </div>

        </div>
        </div>

        <div class="col-md-3 col-sm-10 col-xs-12 home-left col-md-pull-9">
        <div class="thumbnail">
        <div class="caption">
        <h3>What is OpenACS</h3>


        <p class="item">
        <abbr title="Open Architecture Community System">OpenACS</abbr> is a toolkit for building scalable, community-oriented web applications. OpenACS is the foundation for many <a href="/community/sites/">products and websites</a>, including the <a href="http://www.dotlrn.org/">.LRN</a> (pronounced "dot learn") e-learning platform.
        </p>
        <p class="item">
        OpenACS is open source and is available under the <a href="http://www.gnu.org/licenses/gpl.html">GNU General Public License</a>.
        </p>

        </div>
        </div>
        <div class="thumbnail">
        <div class="caption">
        <h3>Download Now!</h3>


        <p>
        <span class="item"><a href="/projects/openacs/download/download/openacs-5.9.1.tar.gz?revision_id=5373766">Version 5.9.1</a> (openacs-5.9.1.tgz)</span>
        <br>
        <span class="item"><a href="/projects/openacs/download/">Available Versions</a></span>
        <br>
        <span class="item"><a href="/xowiki/en/openacs-system-install">Install documentation</a></span>
        </p>
        <p>
        <span class="item"><a href="/xowiki/naviserver-openacs">Generic installer</a></span>
        <br>
        <span class="item"><a href="/xowiki/openacs-system-install-windows-server">Windows Installation</a></span>
        </p>
        <p>
        Once the core system is installed, you can install packages from the
        <span class="item"><a href="/repository/">OpenACS Package Repository</a></span>.
        </p>
        <p>

        </div>
        </div>
        <div class="thumbnail">
        <div class="caption">
        <h3>Community</h3>


        <p class="item">One of the strengths of the OpenACS project is the community surrounding it:</p>
        <ul>
        <li><a href="/forums/">Discussion forums</a></li>
        <li><a href="irc://irc.freenode.net/#openacs">#openacs channel</a> in <abbr title="Internet Relay Chat">IRC</abbr> at freenode.net (<a href="/irc/">More info</a>)</li>
        <li><a href="/xowiki/">Wiki</a></li>
        <li><a href="/storage/">File Storage</a></li>
        </ul>
        <p>We are open to your contributions! If you have an idea, a new piece of documentation, or a patch, we want to hear about it!
        </p>
        <ul>
        <li><a href="/contribute/">Contribute</a>
        </li>
        </ul>
        <p>A number of companies can help you with OpenACS: </p>
        <ul>
        <li><a href="/community/companies/">Support</a>
        </li>
        </ul>


        </div>
        </div>
        <div class="thumbnail">
        <div class="caption">
        <h3>Resources for Developers</h3>


        <p class="item">Resources for developers:</p>
        <ul>
        <li><a href="/xowiki/translation-server">Translation server</a></li>
        <!-- <li><a href="/xowiki/en/Official_test_servers">Test servers</a></li> -->
        <li><a href="/bugtracker/openacs">Bug tracker</a></li>
        <li><a href="http://cvs.openacs.org">CVS browser</a></li>
        </ul>

        </div>
        </div>
        <div class="thumbnail">
        <div class="caption">
        <h3>Sponsors</h3>


        <h4>AOE media GmbH</h4>
        <p class="item">
        <a href="https://www.aoemedia.com/opensource-cms.html" target="_blank">Open Source CMS</a> provider in Germany.
        </p>

        </div>
        </div>

        </div>

        </div>



        <!-- START ETP LINK -->
        <div>
        <span class="etp-link"></span>
        </div>
        <!-- END ETP LINK -->


        </div>

        <!-- START FOOTER -->
        <div class="navbar navbar-default navbar-fixed-bottom" style="border-color:#ccc;">
        <div class="footer" style='margin-top:0;font-size:90%;color:#666;padding-top:5px;'>
        <p style="margin:0;">
        This website is maintained by the OpenACS community. Any problems, email <a href="mailto:webmaster@openacs.org">webmaster</a> or <a href="/bugtracker/openacs.org/">submit</a> a bug report.
        <br>
        (Powered by Tcl<a href="http://www.tcl.tk/"><img alt="Tcl Logo" src="/resources/openacs-bootstrap3-theme/images/plume.png" width="14" height="18"></a>,
         Next Scripting <a href="https://next-scripting.org/"><img alt="NSF Logo" src="/resources/openacs-bootstrap3-theme/images/next-icon.png" width="14" height="8"></a>,
         NaviServer 4.99.18 <a href="http://sourceforge.net/projects/naviserver/"><img src="/resources/openacs-bootstrap3-theme/images/ns-icon-16.png" alt="NaviServer Logo" width="12" height="12"></a>,
         IPv6)
        </p>
        </div>
        </div>
        <!-- END FOOTER -->

        </div>


        <script type="text/javascript" src="/resources/acs-subsite/core.js" nonce="AD0268558620334765298A2E8592D3D3D01A7C1A"></script>


        </body>
        </html>
    }

    set msg "Test case 6: in our index page is removing tags ok"
    set unallowed_tags {div style script}
    set result [ad_dom_sanitize_html -html $test_case \
                    -allowed_tags * \
                    -allowed_attributes * \
                    -allowed_protocols * \
                    -unallowed_tags $unallowed_tags]
    set valid_p [ad_dom_sanitize_html -html $result \
                     -allowed_tags * \
                     -allowed_attributes * \
                     -allowed_protocols * \
                     -unallowed_tags $unallowed_tags \
                     -validate]
    aa_true "$msg with validate?" $valid_p    
    aa_false $msg? [regexp {<(div|style|script)\s*[^>]*>} $result]

    set msg "In our index page is removing attributes ok"
    set unallowed_attributes {id style}
    set result [ad_dom_sanitize_html -html $test_case \
                    -allowed_tags * \
                    -allowed_attributes * \
                    -allowed_protocols * \
                    -unallowed_attributes $unallowed_attributes]
    set valid_p [ad_dom_sanitize_html -html $result \
                     -allowed_tags * \
                     -allowed_attributes * \
                     -allowed_protocols * \
                     -unallowed_attributes $unallowed_attributes \
                     -validate]
    aa_true "$msg with validate?" $valid_p
    aa_false $msg? [regexp {<([a-z]\w*)\s+[^>]*(id|style)=".*"[^>]*>} $result]

    set msg "In our index page is removing protocols ok"
    set unallowed_protocols {http javascript https}
    set result [ad_dom_sanitize_html -html $test_case \
                    -allowed_tags * \
                    -allowed_attributes * \
                    -allowed_protocols * \
                    -unallowed_protocols $unallowed_protocols]
    set valid_p [ad_dom_sanitize_html -html $result \
                     -allowed_tags * \
                     -allowed_attributes * \
                     -allowed_protocols * \
                     -unallowed_protocols $unallowed_protocols \
                     -validate]
    aa_true "$msg with validate?" $valid_p    
    aa_false $msg? [regexp {<([a-z]\w*)\s+[^>]*(href|src|content|action)="(http|javascript):.*"[^>]*>} $result]

    set msg "In our index page is removing outer links ok"
    set result [ad_dom_sanitize_html -html $test_case \
                    -allowed_tags * \
                    -allowed_attributes * \
                    -allowed_protocols * \
                    -no_outer_urls]
    set valid_p [ad_dom_sanitize_html -html $result \
                     -allowed_tags * \
                     -allowed_attributes * \
                     -allowed_protocols * \
                     -no_outer_urls \
                     -validate]
    aa_true "$msg with validate?" $valid_p
    aa_false $msg? [regexp {<([a-z]\w*)\s+[^>]*(href|src|content|action)="(http|https|//):.*"[^>]*>} $result]

}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_js_escape} \
    ad_js_escape {

    Test if ad_js_escape is working as expected

} {
    set string "\"\"\"\"\"\'"
    aa_true " - String of only quotes " {[ad_js_escape $string] eq {\"\"\"\"\"\'}}

    set string   "\n\r\t  \n\n\n \t\t \b \v\v\v  \f"
    set expected {\n\r\t  \n\n\n \t\t \b \v\v\v  \f}
    
    aa_true " - String of only escape sequences " {[ad_js_escape $string] eq $expected}

    set string   "\n\r\t  \na word  \'\n\n \t\"\" aaaaa\' \'\'\'\b \v\v\v  \f"
    set expected {\n\r\t  \na word  \'\n\n \t\"\" aaaaa\' \'\'\'\b \v\v\v  \f}

    ns_log notice EXP:<$expected>
    ns_log notice GOT:<[ad_js_escape $string]>

    aa_true " - String of escape sequences, quotes and text (with some quotes already escaped)" \
        {[ad_js_escape $string] eq $expected}
}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_pad} \
    ad_pad {

    Test if ad_pad is working as expected

} {
    
    aa_section "Testing left pad"

    set string [ad_generate_random_string]
    set length [expr {int(rand()*1000)}]
    set padstring [ad_generate_random_string]

    aa_log " - string: $string"
    aa_log " - length: $length"
    aa_log " - padstring: $padstring"
    
    set result [ad_pad -left $string $length $padstring]

    aa_true " - Result is exactly $length long " {[string length $result] == $length}
    aa_true " - String is at right end " [regexp "^.*${string}\$" $result]

    aa_section "Testing right pad"

    set string [ad_generate_random_string]
    set length [expr {int(rand()*1000)}]
    set padstring [ad_generate_random_string]

    aa_log " - string: $string"
    aa_log " - length: $length"
    aa_log " - padstring: $padstring"
    
    set result [ad_pad -right $string $length $padstring]

    aa_true " - Result is exactly $length long " {[string length $result] == $length}
    aa_true " - String is at left end " [regexp "^${string}.*\$" $result]
    
}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_html_qualify_links} \
    ad_html_qualify_links {

        Test if ad_html_qualify_links is working as expected.
        
        @author Gustaf Neumann
} {
    
    aa_section "Testing without path"

    set rURL "relative/r.txt"
    set aURL "/dotlrn/clubs/club1/mytext.docx"
    set fqURL "https://openacs.org/doc/"
    
    set html [subst {<div><div class="table">
        A relative URL <a href="$rURL">relative/r.txt</a>
        An absolute URL <a href="$aURL">mytext.docx</a>
        A fully qualified URL <a href="$fqURL">Documentation</a>        
    }]
    set result [ad_html_qualify_links -location {http://myhost/} $html]

    aa_true "result contains relative URL NOT expanded" {[string match *href=\"$rURL* $result]}
    aa_true "result contains absolute URL location-prefixed" {[string match *http://myhost$aURL* $result]}
    aa_true "result contains fully qualified URL" {[string match *$fqURL* $result]}

    aa_section "Testing with path"

    set pretty_link "/dotlrn/clubs/club2/uploads/mytext.docx"
    set result [ad_html_qualify_links -location {http://myhost/} -path /somepath $html]

    aa_true "result contains relative URL expanded" {[string match */somepath/$rURL* $result]}
    aa_true "result contains absolute URL location-prefixed" {[string match *http://myhost$aURL* $result]}
    aa_true "result contains fully qualified URL" {[string match *$fqURL* $result]}

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
