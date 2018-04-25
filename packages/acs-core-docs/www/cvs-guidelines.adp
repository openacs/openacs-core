
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {CVS Guidelines}</property>
<property name="doc(title)">CVS Guidelines</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="style-guide" leftLabel="Prev"
			title="Chapter 12. Engineering
Standards"
			rightLink="eng-standards-versioning" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="cvs-guidelines" id="cvs-guidelines"></a> CVS Guidelines</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red"><span class="cvstag">($&zwnj;Id: cvs.xml,v
1.8 2018/03/27 11:18:00 hectorr Exp $)</span></span></p><p>By Joel Aufrecht with input from Jeff Davis, Branimir Dolicki,
and Jade Rubick.</p>
&lt;/authorblurb&gt;
<div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="using-cvs-with-openacs" id="using-cvs-with-openacs"></a>Using CVS with OpenACS</h3></div></div></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140682180426344" id="idp140682180426344"></a>Getting Started</h4></div></div></div><p>All OpenACS code is available anonymously. To get code
anonymously, use the parameter <code class="computeroutput">-d:pserver:anonymous\@cvs.openacs.org:/cvsroot</code>
immediately after <code class="computeroutput">cvs</code> in a cvs
command to check out or export code.</p><p>If you are an OpenACS developer, you should check out code so
that you or any other developer can commit it. To do this, use the
parameter <code class="computeroutput">-d:ext:cvs.openacs.org:/cvsroot</code> immediately
after <code class="computeroutput">cvs</code> in checkout commands.
This will create a local checkout directory that uses
cvs.openacs.org but does not specify the user. By default, it will
use your local account name as the user, so if you are logged in as
"foobar" it will try to check out and commit as if you
had specified <code class="computeroutput">:ext:foobar\@cvs.openacs.org:/cvsroot</code>. The
advantage of not specifying a user in the checkout command is that
other users can work in the directory using their own accounts.</p><p>OpenACS.org supports non-anonymous cvs access only over ssh, so
you must have <code class="computeroutput">CVS_RSH=ssh</code> in
your environment. (Typically this is accomplished by putting
<code class="computeroutput">export CVS_RSH=ssh</code> into
<code class="computeroutput">~/.bash_profile</code>.). If your
local account name does not match your cvs.openacs.org account
name, create a file <code class="computeroutput">~/.ssh/config</code> with an entry like:</p><pre class="programlisting">Host cvs.openacs.org
    User joel
</pre><p>With this setup, you will be asked for your password with each
cvs command. To avoid this, set up ssh certificate authentication
for your OpenACS account. (<a class="ulink" href="https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server" target="_top">More information</a>)</p><p>You may want to set some more default actions for CVS usage. To
do so, create the file <code class="computeroutput">~/.cvsrc</code>
with the contents:</p><pre class="screen"><span class="action">cvs -z6
cvs -q</span></pre><p>
<code class="computeroutput">-z6</code> speeds up cvs access
over the network quite a bit by enabling compressed connection by
default. <code class="computeroutput">-q</code> suppresses some
verbose output from commands. For example, it makes the output of
<code class="computeroutput">cvs up</code> much easier to read.</p><div class="sidebar">
<div class="titlepage"><div><div><p class="title"></p></div></div></div><p>Administrator Note: These are the steps to grant CVS commit
rights to a user:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>Create the user&#39;s account. On cvs.openacs.org:</p><pre class="screen"><span class="action">sudo bash
/usr/sbin/useradd -c "<em class="replaceable"><code>Real Name</code></em>" -G cvs -p <em class="replaceable"><code>passwd</code></em><em class="replaceable"><code>username</code></em>
/usr/sbin/usermod -G cvs,<em class="replaceable"><code>username</code></em><em class="replaceable"><code>username</code></em>
</span></pre>
</li><li class="listitem">
<p>Grant cvs access to the user account. On any machine, in a
temporary directory:</p><pre class="screen"><span class="action">cvs -d :ext:cvs.openacs.org:/cvsroot co CVSROOT
cd CVSROOT
emacs avail</span></pre><p>Add an avail line of the form:</p><pre class="programlisting">avail|<em class="replaceable"><code>username</code></em>|openacs-4</pre><pre class="screen"><span class="action">cvs commit -m "added commit on X for username" avail</span></pre>
</li>
</ol></div>
</div><div class="sidebar">
<div class="titlepage"><div><div><p class="title"></p></div></div></div><p>Branimir suggests an additional level of abstraction. If you
put</p><pre class="programlisting">Host cvs-server
      HostName cvs.openacs.org
      User <em class="replaceable"><code>yournamehere</code></em>
</pre><p>into your <code class="computeroutput">~/.ssh/config</code>
file, then you can use <code class="computeroutput">-d
:ext:cvs-server:/cvsroot</code> instead of <code class="computeroutput">-d :ext:cvs.openacs.org:/cvsroot</code>. You can
then change the definition of <code class="computeroutput">cvs-server</code> by changing one file instead of
editing hundreds of <code class="computeroutput">CVSROOT/Repository</code> files.</p>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140682180426472" id="idp140682180426472"></a>Checkout for Package Development</h4></div></div></div><p>If you are actively developing a non-core package, you should
work from the latest core release branch. Currently this is
oacs-5-9. This ensures that you are working on top of a stable
OpenACS core, but still allows you to commit feature changes to
non-core packages. To check out all packages,</p><pre class="screen"><span class="action">cvs -d :ext:cvs.openacs.org:/cvsroot co -r oacs-5-9 openacs-4</span></pre><p>If you work in the directories created with this command, all of
your cvs updates and commits will be confined to the oacs-5-9
branch. Your work will be merged back to HEAD for you with each
release.</p><p>Because the entire openacs-4 directory is large, you may want to
use only acs-core plus some specific modules. To do this, check out
core first:</p><pre class="screen"><span class="action">cvs -d:ext:cvs.openacs.org:/cvsroot -r oacs-5-9 checkout acs-core</span></pre><p>Then add modules as needed:</p><pre class="screen"><span class="action">cd /var/lib/aolserver/<em class="replaceable"><code>service0</code></em>/packages
cvs up -d <em class="replaceable"><code>packagename</code></em>
</span></pre><p>... where <em class="replaceable"><code>packagename</code></em>
is the name of the package you want. Visit the <a class="ulink" href="http://openacs.org/packages" target="_top">Package
Inventory</a> and <a class="ulink" href="http://openacs.org/projects/openacs/packages/" target="_top">Package maintainers and status</a> for a list of available
packages and their current state.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140682174276520" id="idp140682174276520"></a>Checkout for Core Development</h4></div></div></div><p>If you are actively developing packages in the OpenACS Core,
work from the HEAD branch. HEAD is used for active development of
the next version of core OpenACS. It may be very buggy; it may not
even install correctly. Do not use this branch for development of
non-core features unless your work depends on some of the HEAD core
work. To check out HEAD, omit the <code class="computeroutput">-r</code> tag.</p><p>To check out HEAD for development, which requires an OpenACS
developer account:</p><pre class="screen"><span class="action">cvs -d:ext:cvs.openacs.org:/cvsroot checkout acs-core</span></pre><p>To check out HEAD anonymously:</p><pre class="screen"><span class="action">cvs -d:pserver:anonymous\@cvs.openacs.org:/cvsroot checkout acs-core</span></pre>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140682187843192" id="idp140682187843192"></a>Checkout .LRN</h4></div></div></div><p>.LRN consists of a given version OpenACS core, plus a set of
packages. These are collectively packages together to form a
distribution of .LRN. F .LRN 2.0.0 sits on top of OpenACS 5.0.0.
.LRN also uses an OpenACS install.xml file during installation;
this file is distributed within the dotlrn package and must be
moved. To get a development checkout of .LRN in the subdirectory
<code class="literal">dotlrn</code>:</p><pre class="screen"><span class="action">cvs -d :pserver:anonymous\@cvs.openacs.org:/cvsroot checkout -r oacs-5-9 acs-core
mv openacs-4 dotlrn
cd dotlrn/packages
cvs -d :pserver:anonymous\@cvs.openacs.org:/cvsroot checkout -r oacs-5-9 dotlrn-all
mv dotlrn/install.xml ..</span></pre>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="working-with-cvs" id="working-with-cvs"></a>Working with CVS</h4></div></div></div><p>Once you have a checkout you can use some commands to track what
has changed since you checked out your copy. <code class="computeroutput">cvs -n update</code> does not change any files,
but reports which changes have been updated or locally modified, or
are not present in CVS.</p><p>To update your files, use <code class="computeroutput">cvs
update</code>. This will merge changes from the repository with
your local files. It has no effect on the cvs.openacs.org
repository.</p>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="openacs-cvs-concepts" id="openacs-cvs-concepts"></a>OpenACS CVS Concepts</h3></div></div></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140682182311736" id="idp140682182311736"></a>Modules</h4></div></div></div><p>All OpenACS code resides within a single CVS module,
<code class="computeroutput">openacs-4</code>. (The openacs-4
directory contains code for all versions of OpenACS 4 and later,
and .LRN 1 and later.) Checking out this module retrieves all
OpenACS code of any type. For convenience, subsets of <code class="computeroutput">openacs-4</code> are repackaged as smaller
modules.</p><p>
<code class="computeroutput">acs-core</code> contains only
critical common packages. It does not have any user applications,
such as forums, bug-tracker, calendar, or ecommerce. These can be
added at any time.</p><p>The complete list of core packages is:</p><pre class="programlisting">acs-admin 
acs-api-browser 
acs-authentication 
acs-automated-testing 
acs-bootstrap-installer
acs-content-repository 
acs-core-docs 
acs-kernel 
acs-lang 
acs-mail
acs-messaging 
acs-reference 
acs-service-contract 
acs-subsite 
acs-tcl
acs-templating 
ref-timezones search</pre><p>
<code class="computeroutput">dotlrn-all</code> contains the
packages required, in combination with acs-core, to run the .LRN
system.</p><p>
<code class="computeroutput">project-manager-all</code> contains
the packages required, in combination with acs-core, to run the
project-manager package.</p><p>Each OpenACS package (i.e., directory in <code class="computeroutput">openacs-4/packages/</code>) is also aliased as a
module of the same name.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140682176987896" id="idp140682176987896"></a> Tags and Branches</h4></div></div></div><p>Tags and Branches look similar in commands, but behave
differently. A tag is a fixed point on a branch. Check out a tag to
get a specific version of OpenACS. Check out a branch to get the
most current code for that major-minor version (e.g., 5.0.x or
5.1.x). You can only commit to a branch, not a tag, so check out a
branch if you will be working on the code.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<code class="computeroutput">openacs-<em class="replaceable"><code>x</code></em>-<em class="replaceable"><code>y</code></em>-<em class="replaceable"><code>z</code></em>-final</code> tags mark final
releases of OpenACS. This tag is applied to the acs-core files for
an OpenACS core release, and to the latest released versions of all
other packages at the time of release. Example: <code class="computeroutput">openacs-5-0-4-final</code>.</p></li><li class="listitem"><p>
<code class="computeroutput">dotlrn-<em class="replaceable"><code>x</code></em>-<em class="replaceable"><code>y</code></em>-<em class="replaceable"><code>z</code></em>-final</code> tags mark final
releases of .LRN. These tags apply only to .LRN packages. Example:
<code class="computeroutput">dotlrn-2-0-1-final</code>
</p></li><li class="listitem"><p>
<code class="computeroutput">
<em class="replaceable"><code>packagename</code></em>-<em class="replaceable"><code>x</code></em>-<em class="replaceable"><code>y</code></em>-<em class="replaceable"><code>z</code></em>-final</code> tags apply to
releases of individual packages. For example, <code class="computeroutput">calendar-2-0-0-final</code> is a tag that will
retrieve only the files in the calendar 2.0.0 release. It applies
only to the calendar package. All non-core, non-dotlrn packages
should have a tag of this style, based on the package name. Many
packages have not been re-released since the new naming convention
was adopted and so don&#39;t have a tag of this type.</p></li><li class="listitem">
<p>
<code class="computeroutput">openacs-<em class="replaceable"><code>x</code></em>-<em class="replaceable"><code>y</code></em>-compat</code> tags point to the
most recent released version of OpenACS <em class="replaceable"><code>X</code></em>.<em class="replaceable"><code>Y</code></em>. It is similar to
openacs-x-y-z-compat, except that it will always get the most
recent dot-release of Core and the most recent compatible, released
version of all other packages. All of the other tag styles should
be static, but -compat tags may change over time. If you want
version 5.0.4 exactly, use the openacs-5-0-4-final tag. If you want
the best newest released code in the 5.0.x release series and you
want to upgrade within 5.0.x later, use the compat tag.</p><p>For example, if you check out the entire tree with -r
openacs-5-0-compat, you might get version 5.0.4 of each OpenACS
core package, version 2.0.1 of calendar, version 2.0.3 of each .LRN
package, etc. If you update the checkout two months later, you
might get version 5.0.5 of all OpenACS core packages and version
2.1 of calendar.</p>
</li><li class="listitem">
<p>oacs-<em class="replaceable"><code>x</code></em>-<em class="replaceable"><code>y</code></em> is a <span class="emphasis"><em>branch,</em></span> , not a tag. All core packages
in the 5.0 release series (5.0.0, 5.0.1, 5.0.2, etc) are also on
the oacs-5-0 branch. Similarly, OpenACS core packages for 5.1.0 are
on the oacs-5-1 branch.</p><p>These branches are used for two purposes. OpenACS Core packages
on these branches are being tidied up for release. Only bug fixes,
not new features, should be added to core packages on release
branches. For all other packages, release branches are the
recommended location for development. For example, if you are
working on calendar, which is compatible with OpenACS 5.0 but not
5.1, work on the oacs-5-0 branch.</p>
</li><li class="listitem"><p>
<code class="computeroutput">HEAD</code> is a branch used for
development of core packages.</p></li>
</ul></div>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="contributing-code" id="contributing-code"></a>Contributing code back to OpenACS</h3></div></div></div><p>There are three main ways to contribute code to OpenACS:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>To contribute a small fix, if you do not have a developer
account, submit a <a class="ulink" href="http://openacs.org/bugtracker/openacs/patch-submission-instructions.htm" target="_top">patch</a>.</p></li><li class="listitem">
<p>If you are making many changes, or would like to become a direct
contributor, send mail to <a class="ulink" href="mailto:oct\@openacs.org" target="_top">the Core Team</a> asking for
commit rights. You can then commit code directly to the
repository:</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Use one of the checkout methods described above to get files to
your system. This takes the place of steps 1 and 2 in <a class="xref" href="openacs" title="Installation Option 2: Install from tarball">the section called
“Installation Option 2: Install from tarball”</a>. Continue setting
up the site as described there.</p></li><li class="listitem"><p>Fix bugs and add features.</p></li><li class="listitem">
<p>Commit that file (or files):</p><pre class="screen"><span class="action">cvs commit -m "what I did and why" filename</span></pre><p>Because this occurs in your personal checkout and not an
anonymous one, this commit automagically moves back upstream to the
Mother Ship repository at cvs.openacs.org. The names of the changed
files, and your comments, are sent to a mailing list for OpenACS
developers. A Core Team developer may review or roll back your
changes if necessary.</p>
</li><li class="listitem"><p>Confirm via the <a class="ulink" href="http://cvs.openacs.org/browse/OpenACS/openacs-4/" target="_top">OpenACS CVS browser</a> that your changes are where you
intended them to be.</p></li>
</ol></div>
</li><li class="listitem">
<p>Add a new package. Contact the <a class="ulink" href="mailto:oct\@openacs.org" target="_top">Core Team</a> to get
approval and to get a module alias created.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem">
<p>Check out acs-core on the HEAD branch. (Weird things happen if
you add files to a branch but not to HEAD):</p><pre class="screen"><span class="action">cd /tmp
cvs -d:ext:cvs.openacs.org:/cvsroot checkout acs-core</span></pre><p>Copy your package directory from your working directory to this
directory. Make sure not to copy any CVS directories.</p><pre class="screen"><span class="action">cp -r /var/lib/aolserver/<em class="replaceable"><code>service0</code></em>/packages/<em class="replaceable"><code>newpackage</code></em> /tmp/openacs-4/packages</span></pre><p>Import the package into the cvs.openacs.org cvs repository:</p><pre class="screen"><span class="action">cd /tmp/openacs-4/packages/<em class="replaceable"><code>newpackage</code></em>
cvs import -m "Initial import of <em class="replaceable"><code>newpackage</code></em>" openacs-4/packages/newpackage <em class="replaceable"><code>myname</code></em><em class="replaceable"><code>newpackage-0-1d</code></em>
</span></pre>
</li><li class="listitem">
<p>Add the new package to the modules file. (An administrator has
to do this step.) On any machine, in a temporary directory:</p><pre class="screen"><span class="action">cvs -d :ext:cvs.openacs.org:/cvsroot co CVSROOT
cd CVSROOT
emacs modules</span></pre><p>Add a line of the form:</p><pre class="programlisting">
<em class="replaceable"><code>photo-album-portlet</code></em> openacs-4/packages/<em class="replaceable"><code>photo-album-portlet</code></em>
</pre><p>Commit the change:</p><pre class="screen"><span class="action">cvs commit -m "added alias for package <em class="replaceable"><code>newpackage</code></em>" modules</span></pre><p>This should print something like:</p><div class="literallayout"><p>cvs commit: Examining .<br>
**** Access allowed: Personal Karma exceeds Environmental Karma.<br>

Checking in modules;<br>
/cvsroot/CVSROOT/modules,v  &lt;--  modules<br>
new revision: 1.94; previous revision: 1.93<br>

done<br>
cvs commit: Rebuilding administrative file database</p></div>
</li><li class="listitem">
<p>Although you should add your package on HEAD, you should do
package development on the latest release branch that your code is
compatible with. So, after completing the import, you may want to
branch your package:</p><pre class="programlisting">cd /var/lib/aolserver/<em class="replaceable"><code>service0</code></em>/packages/<em class="replaceable"><code>newpackage</code></em>
cvs tag -b <em class="replaceable"><code>oacs-5-1</code></em>
</pre>
</li><li class="listitem"><p>See <a class="xref" href="releasing-package" title="How to package and release an OpenACS Package">the section called
“How to package and release an OpenACS Package”</a>
</p></li>
</ol></div><div class="note" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">Note</h3><p>Some packages are already in cvs at <code class="computeroutput">openacs-4/contrib/packages</code>. Starting with
OpenACS 5.1, we have a Maturity mechanism in the APM which makes
the <code class="computeroutput">contrib</code> directory
un-necessary. If you are working on a <code class="computeroutput">contrib</code> package, you should move it to
<code class="computeroutput">/packages</code>. This must be done by
an OpenACS administrator. On cvs.openacs.org:</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><pre class="programlisting">
cp -r /cvsroot/openacs-4/contrib/packages/<em class="replaceable"><code>package0</code></em> /cvsroot/openacs-4/packages</pre></li><li class="listitem"><p>Update the modules file as described above.</p></li><li class="listitem"><p>Remove the directory from cvs in the old location using
<code class="computeroutput">cvs rm</code>. One approach
<code class="computeroutput">for file in `find | grep -v CVS`; do
rm $file; cvs remove $file; done</code>
</p></li>
</ol></div>
</div>
</li>
</ol></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Commit_Rules" id="Commit_Rules"></a>
Rules for Committing Code to the OpenACS repository</h4></div></div></div><p>CVS commit procedures are governed by <a class="ulink" href="http://openacs.org/forums/message-view?message_id=185506" target="_top">TIP (Technical Improvement Proposal) #61: Guidelines for CVS
committers</a>
</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>Which branch?</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>For core packages, new features should always be committed on
HEAD, not to release branches.</p></li><li class="listitem"><p>For core packages, bug fixes should be committed on the current
release branch whenever applicable.</p></li><li class="listitem">
<p>For non-core packages, developers should work on a checkout of
the release branch of the lastest release. For example, if OpenACS
5.1.0 is released, developers should work on the oacs-5-1 branch.
When oacs-5-2 is branched, developers should continue working on
oacs-5-1 until OpenACS 5.2.0 is actually released.</p><p><span class="emphasis"><em>Reason: First, this ensures that
developers are working against stable core code. Second, it ensures
that new package releases are available to OpenACS users
immediately.</em></span></p>
</li><li class="listitem"><p>The current release branch is merged back to HEAD after each dot
release.</p></li>
</ol></div>
</li><li class="listitem"><p>New packages should be created in the <code class="computeroutput">/packages</code> directory and the maturity flag
in the .info file should be zero. This is a change from previous
policy, where new packages went to /contrib/packages)</p></li><li class="listitem">
<p>Code</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Only GPL code and material should be committed to the OpenACS
CVS repository (cvs.openacs.org)</p></li><li class="listitem"><p>Do not mix formatting changes with code changes. Instead, make a
formatting-only change which does not affect the logic, and say so
in the commit comment. Then, make the logic change in a separate
commit. <span class="emphasis"><em>Reason: This makes auditing and
merging code much easier.</em></span>
</p></li><li class="listitem">
<p>Database upgrade scripts should only span one release increment,
and should follow <a class="ulink" href="http://openacs.org/doc/current/eng-standards-versioning.html#naming-upgrade-scripts" target="_top">Naming Database Upgrade Scripts</a> .</p><p><span class="emphasis"><em>Reason: If an upgrade script ends
with the final release number, then if a problem is found in a
release candidate it cannot be addressed with another upgrade
script. E.g., the last planned upgrade script for a package
previously in dev 1 would be upgrade-2.0.0d1-2.0.0b1.sql, not
upgrade-2.0.0d1-2.0.0.sql. Note that using rc1 instead of b1 would
be nice, because that&#39;s the convention with release codes in
cvs, but the package manager doesn&#39;t support rc
tags.</em></span></p>
</li><li class="listitem"><p>Database upgrade scripts should never go to the release version,
e.g., should always have a letter suffix such as d1 or b1.</p></li><li class="listitem"><p>CVS commit messages should be intelligible in the context of
Changelogs. They should not refer to the files or versions.</p></li><li class="listitem"><p>CVS commit messages and code comments should refer to bug, tip,
or patch number if appropriate, in the format "resolves bug
11", "resolves bugs 11, resolves bug 22".
"implements tip 42", "implements tip 42, implements
tip 50", "applies patch 456 by User Name",
"applies patch 456 by User Name, applies patch 523 by
...".</p></li>
</ol></div>
</li><li class="listitem">
<p>When to TIP</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>A TIP is a Techical Improvement Proposal ( <a class="ulink" href="http://openacs.org/forums/message-view?message_id=115576" target="_top">more information</a> ). A proposed change must be
approved by TIP if:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>It changes the core data model, or</p></li><li class="listitem"><p>It will change the behavior of any core package in a way that
affects existing code (typically, by changing public API), or</p></li><li class="listitem"><p>It is a non-backwards-compatible change to any core or standard
package.</p></li>
</ol></div>
</li><li class="listitem">
<p>A proposed change need not be TIPped if:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>it adds a new function to a core package in a way that:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>does not change the backwards-compatibility of public API
functions.</p></li><li class="listitem"><p>does not change the data model</p></li><li class="listitem"><p>has no negative impact on performance</p></li>
</ol></div>
</li><li class="listitem"><p>it changes private API, or</p></li><li class="listitem"><p>it is a change to a non-core, non-standard package</p></li>
</ol></div>
</li>
</ol></div>
</li><li class="listitem">
<p>Tags</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>When a package is released in final form, the developer shall
tag it "packagename-x-y-z-final" and
"openacs-x-y-compat". x-y should correspond to the
current branch. If the package is compatible with several different
core versions, several compat tags should be applied.</p><p><span class="emphasis"><em>Reason 1: The packagename tag is a
permanent, static tag that allows for future comparison. The compat
tag is a floating tag which is used by the repository generator to
determine the most recent released version of each package for each
core version. This allows package developers to publish their
releases to all users of automatic upgrade without any intervention
from the OpenACS release team.Reason 2: The compat tags allows CVS
users to identify packages which have been released since the last
core release.Reason 3: The compat tag or something similar is
required to make Rule 6 possible.</em></span></p>
</li><li class="listitem">
<p>When OpenACS core is released, the openacs-x-y-z-final tag shall
be applied to all compat packages.</p><p><span class="emphasis"><em>Reason: This allows OpenACS
developers who are creating extensively customized sites to branch
from a tag which is stable, corresponds to released code instead of
development code, and applies to all packages. This tag can be used
to fork packages as needed, and provides a common ancestor between
the fork and the OpenACS code so that patches can be
generated.</em></span></p>
</li>
</ol></div><p>For example, adding a new API function wouldn&#39;t require a
TIP. Changing an existing API function by adding an optional new
flag which defaults to no-effect wouldn&#39;t require a TIP. Added
a new mandatory flag to an existing function would require a
TIP.</p>
</li>
</ol></div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140682187073560" id="idp140682187073560"></a> Informal Guidelines</h4></div></div></div><p>Informal guidelines which may be obsolete in places and should
be reviewed:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Before committing to cvs you must submit a bug report and patch
to the <a class="ulink" href="http://openacs.org/bugtracker/openacs" target="_top">OpenACS bug
tracker</a> . The only exceptions to this rule are for <a class="ulink" href="/projects/openacs/4.7/package_inventory" target="_top">package maintainers</a> committing in a package they are
maintaining and for members of the core team.</p></li><li class="listitem"><p>If you are committing a bug fix you need to coordinate with the
package maintainer. If you are a maintainer then coordinate with
any fellow maintainers.</p></li><li class="listitem"><p>If you are to commit a new feature, an architecture change, or a
refactoring, you must coordinate with the OpenACS core team first.
Also, such changes should have a discussion in the forums to allow
for feedback from the whole community.</p></li><li class="listitem"><p>If you are changing the data model you *must* provide an upgrade
script and bump up the version number of the package.</p></li><li class="listitem"><p>Consider any upgradability ramifications of your change. Avoid
changing the contract and behaviour of Tcl procedures. If you want
to build a new and clean API consider deprecating the old proc and
making it invoke the new one.</p></li><li class="listitem"><p>Never rush to commit something. Before committing double check
with cvs diff what exactly you are committing.</p></li><li class="listitem"><p>Always accompany a commit with a brief but informative comment.
If your commit is related to bug number N and/or patch number P,
indicate this in the commit comment by including "bug N"
and/or "patch P". This allows us to link bugs and patches
in the Bug Tracker with changes to the source code. For example
suppose you are committing a patch that closes a missing HTML tag,
then an appropriate comment could be "Fixing bug 321 by
applying patch 134. Added missing h3 HTML close tag".</p></li><li class="listitem"><p>Commit one cohesive bug fix or feature change at a time.
Don&#39;t put a bunch of unrelated changes into one commit.</p></li><li class="listitem"><p>Before you throw out or change a piece of code that you
don&#39;t fully understand, use cvs annotate and cvs log on the
file to see who wrote the code and why. Consider contacting the
author.</p></li><li class="listitem"><p>Test your change before committing. Use the OpenACS package
acs-automated-testing to test Tcl procedures and the tool <a class="ulink" href="http://tclwebtest.sourceforge.net" target="_top">Tclwebtest</a> to test pages</p></li><li class="listitem"><p>Keep code simple, adhere to conventions, and use comments
liberally.</p></li><li class="listitem"><p>In general, treat the code with respect, at the same time, never
stop questioning what you see. The code can always be improved,
just make sure you change the code in a careful and systematic
fashion.</p></li>
</ul></div>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="cvs-resources" id="cvs-resources"></a>Additional Resources for CVS</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The <a class="ulink" href="http://cvs.openacs.org/" target="_top">OpenACS cvs web browser</a> is a useful tools in
understanding what is happening with the code.</p></li><li class="listitem"><p>There is general information about CVS at <a class="ulink" href="http://www.nongnu.org/cvs/" target="_top">nongnu.org</a> .</p></li><li class="listitem"><p><a class="ulink" href="http://web.mit.edu/gnu/doc/html/cvs_20.html" target="_top">cvs
manual</a></p></li><li class="listitem"><p><a class="ulink" href="http://cvsbook.red-bean.com/cvsbook.html" target="_top">Open Source Development with CVS, 3rd Edition</a></p></li><li class="listitem"><p><a class="ulink" href="http://www.piskorski.com/docs/cvs-conventions.html" target="_top">Piskorski&#39;s cvs refs</a></p></li><li class="listitem"><p><a class="ulink" href="http://openacs.org/doc/current/backups-with-cvs.html" target="_top">backup with cvs</a></p></li><li class="listitem"><p><a class="ulink" href="http://openacs.org/forums/message-view?message_id=178551" target="_top">merging 2 file hierarchies with cvs</a></p></li>
</ul></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="style-guide" leftLabel="Prev" leftTitle="OpenACS Style Guide"
			rightLink="eng-standards-versioning" rightLabel="Next" rightTitle="Release Version Numbering"
			homeLink="index" homeLabel="Home" 
			upLink="eng-standards" upLabel="Up"> 
		    