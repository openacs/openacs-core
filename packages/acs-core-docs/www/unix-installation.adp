
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install a Unix-like system and supporting software}</property>
<property name="doc(title)">Install a Unix-like system and supporting software</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="complete-install" leftLabel="Prev"
		    title="
Chapter 3. Complete Installation"
		    rightLink="oracle" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="unix-installation" id="unix-installation"></a>Install a Unix-like system and
supporting software</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel Aufrecht</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="unix-install" id="unix-install"></a>a
Unix-like system</h3></div></div></div><p>Most of the documentation in this section is kept as a
reference. More up-to-date documentation is in the <a class="ulink" href="http://openacs.org/xowiki/openacs-system-install" target="_top">install sections in the Wiki</a>.</p><p>You will need a computer running a unix-like system with the
following software installed:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>tdom</p></li><li class="listitem"><p>tcl --if you plan to use the OpenACS installation script</p></li><li class="listitem">
<p>gmake and the compile and build environment.</p><div class="note" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">BSD Note</h3><p>BSD users: in most places in these instructions, gmake will work
better than make. (<a class="ulink" href="http://openacs.org/forums/message-view?message_id=136910" target="_top">more information on FreeBSD installation</a>). Also, fetch
is a native replacement for wget.</p>
</div>
</li>
</ul></div><p>Note: Instructions for installing tDOM and threaded Tcl are
included with the AOLserver4 installation instructions, if these
are not yet installed.</p><p>The following programs may be useful or required for some
configurations. They are included in most distributions:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>emacs</p></li><li class="listitem"><p>cvs (and <a class="link" href="install-cvs" title="Initialize CVS (OPTIONAL)">initialize</a> it)</p></li><li class="listitem"><p>ImageMagick (used by some packages for server side image
manipulation)</p></li><li class="listitem"><p>Aspell (<a class="ulink" href="http://openacs.org/forums/message-view?message_id=130549" target="_top">more information on spell-checking</a>)</p></li><li class="listitem"><p>DocBook and supporting software (and <a class="link" href="psgml-for-emacs" title="Add PSGML commands to emacs init file (OPTIONAL)">install</a>
emacs keybindings for DocBook SGML)</p></li><li class="listitem"><p>daemontools (<a class="link" href="install-daemontools" title="Install Daemontools (OPTIONAL)">install from source</a>)</p></li><li class="listitem"><p>a Mail Transport Agent, such as exim or sendmail (or <a class="link" href="install-qmail" title="Install qmail (OPTIONAL)">install qmail from source</a>)</p></li>
</ul></div><p>In order to cut and paste the example code into your shell, you
must first do <a class="xref" href="install-steps" title="Setting a global shell variable for cut and paste">Setting a
global shell variable for cut and paste</a>.</p><p>To install a machine to the specifications of the Reference
Platform, do the <a class="link" href="install-redhat" title="Appendix A. Install Red Hat 8/9">walkthrough
of the Red Hat 8.0 Install for OpenACS</a>.</p><div class="cvstag">($&zwnj;Id: os.xml,v 1.15.14.2 2017/04/22 17:18:48
gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="complete-install" leftLabel="Prev" leftTitle="
Chapter 3. Complete Installation"
		    rightLink="oracle" rightLabel="Next" rightTitle="Install Oracle 8.1.7"
		    homeLink="index" homeLabel="Home" 
		    upLink="complete-install" upLabel="Up"> 
		