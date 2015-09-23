
<property name="context">{/doc/acs-core-docs {Documentation}} {Upgrading the OpenACS files}</property>
<property name="doc(title)">Upgrading the OpenACS files</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="upgrade-5-0-dot" leftLabel="Prev"
		    title="
Chapter 5. Upgrading"
		    rightLink="upgrade-supporting" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="upgrade-openacs-files" id="upgrade-openacs-files"></a>Upgrading
the OpenACS files</h2></div></div></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140480063459216" id="idp140480063459216"></a>Chosing a Method to Upgrade your
Files</h3></div></div></div><p>OpenACS is distributed in many different ways:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>as a collection of files</p></li><li class="listitem"><p>as one big tarball</p></li><li class="listitem"><p>via CVS</p></li><li class="listitem"><p>via automatic download from within the APM (package manager)</p></li>
</ul></div><p>Upgrades work by first changing the file system (via any of the
previous methods), and then using the APM to scan the file system,
find upgrade scripts, and execute them. Starting with OpenACS 5.0,
the last method was added, which automatically changes the file
system for you. If you are using the last method, you can skip this
page. This page describes whether or not you need to be upgrading
using this page or not: <a class="xref" href="upgrade-5-0-dot" title="Upgrading an OpenACS 5.0.0 or greater installation">the
section called â€œUpgrading an OpenACS 5.0.0 or
greater installationâ€</a>
</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140480063464304" id="idp140480063464304"></a>Methods of upgrading OpenACS files</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<b>Upgrading files for a site which is not in a CVS
repository. </b>Unpack the tarball into a new directory
and copy its contents on top of your working directory. Or just
'install software', select remote repository, and upgrade your
files from there.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cd /var/lib/aolserver</code></strong>
[$OPENACS_SERVICE_NAME web]$ <strong class="userinput"><code>tar xzf /var/tmp/openacs-5-1.tar.gz</code></strong>
[$OPENACS_SERVICE_NAME web]$ <strong class="userinput"><code>cp -r openacs-5-1/* openacs-4</code></strong>
[$OPENACS_SERVICE_NAME openacs-upgrade]$ <strong class="userinput"><code>exit</code></strong>
[root root]#
<span class="action"><span class="action">su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
cd /var/lib/aolserver
tar xzf /var/tmp/openacs-5-1.tgz
cp -r openacs-5-1/* openacs-4
exit</span></span>
</pre>
</li><li class="listitem">
<p><span class="strong"><strong>Upgrading files for a site in a
private CVS repository</strong></span></p><p>Many OpenACS site developers operate their own CVS repository to
keep track of local customizations. In this section, we describe
how to upgrade your local CVS repository with the latest OpenACS
version, without overriding your own local customizations.</p><p>This diagram explains the basic idea. However, the labels are
incorrect. Step 1(a) has been removed, and Step 1(b) should be
labelled Step 1.</p><div class="figure">
<a name="idp140480063474416" id="idp140480063474416"></a><p class="title"><b>Figure 5.2. Upgrading a
local CVS repository</b></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/upgrade-cvs.png" align="middle" alt="Upgrading a local CVS repository"></div></div>
</div><br class="figure-break"><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>
<b>Step 0: Set up a working CVS checkout. </b>To get
your OpenACS code into your local CVS repository, you will set up a
working CVS checkout of OpenACS. When you want to update your site,
you'll update the working CVS checkout, import those changes into
your local CVS checkout, create a temporary CVS checkout to merge
your local changes, fix any conflicts, commit your changes, and
then update your site. It sounds complicated, but it's not too bad,
and it is the best way to work around CVS's limitations.</p><p>This part describes how to set up your working CVS checkout.
Once it is set up, you'll be able to update any packages using the
existing working CVS checkout. We use one dedicated directory for
each branch of OpenACS - if you are using OpenACS 5.1,x, you will
need a 5.1 checkout. That will be good for 5.1, 5.11, 5.12, and so
on. But when you want to upgrade to OpenACS 5.2, you'll need to
check out another branch.</p><p>The <span class="replaceable"><span class="replaceable">openacs-5-1-compat</span></span> tag identifies the
latest released version of OpenACS 5.1 (ie, 5.1.3 or 5.1.4) and the
latest compatible version of each package. Each minor release of
OpenACS since 5.0 has this tagging structure. For example, OpenACS
5.1.x has <code class="computeroutput">openacs-5-1-compat</code>.</p><p>You will want to separately check out all the packages you are
using.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cd /var/lib/aolserver</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cvs -d :pserver:anonymous\@cvs.openacs.org:/cvsroot checkout -r <span class="replaceable"><span class="replaceable">openacs-5-1-compat</span></span> acs-core</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cd openacs-4/packages</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cvs -d :pserver:anonymous\@cvs.openacs.org:/cvsroot checkout -r <span class="replaceable"><span class="replaceable">openacs-5-1-compat</span></span><span class="replaceable"><span class="replaceable">packagename packagename2...</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cd ../..</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>mv openacs-4 <span class="replaceable"><span class="replaceable">openacs-5-1</span></span>
</code></strong>
</pre><p>Make sure your working CVS checkout doesn't have the entire CVS
tree from OpenACS. A good way to check this is if it has a contrib
directory. If it does, you probably checked out the entire tree.
You might want to start over, remove your working CVS checkout, and
try again.</p>
</li><li class="listitem">
<p><b>Step 1: Import new OpenACS code. </b></p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">
<p>
<b>Update CVS. </b>Update your local CVS working
checkout (unless you just set it up).</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">openacs-5-1</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cvs up -Pd ChangeLog *.txt bin etc tcl www packages/*</code></strong>
</pre>
</li><li class="listitem">
<p>
<b>Update a single package via cvs working
checkout. </b>You can add or upgrade a single package
at a time, if you already have a cvs working directory.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cd /var/lib/aolserver/packages/<span class="replaceable"><span class="replaceable">openacs-5-1</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME openacs-5-1]$ <strong class="userinput"><code>cvs up -Pd <span class="replaceable"><span class="replaceable">packagename</span></span>
</code></strong>
</pre><p>In the next section, the import must be tailored to just this
package.</p>
</li>
</ul></div>
</li><li class="listitem">
<p>
<b>Step 2: Merge New OpenACS code. </b>Now that you
have a local copy of the new OpenACS code, you need to import it
into your local CVS repository and resolve any conflicts that
occur.</p><p>Import the new files into your cvs repository; where they match
existing files, they will become the new version of the file.</p><pre class="screen">
[$OPENACS_SERVICE_NAME openacs-5-1]$ <strong class="userinput"><code> cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">openacs-5-1</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME openacs-5-1]$ <strong class="userinput"><code> cvs -d /var/lib/cvs import -m "upgrade to OpenACS 5.1" <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> OpenACS <span class="replaceable"><span class="replaceable">openacs-5-1</span></span>
</code></strong>
</pre><div class="tip" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">Tip</h3><p>If adding or upgrading a single package, run the cvs import from
within the base directory of that package, and adjust the cvs
command accordingly. In this example, we are adding the
<code class="computeroutput">myfirstpackage</code> package.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">openacs-5-0</span></span>/package/<span class="replaceable"><span class="replaceable">myfirstpackage</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME myfirstpackage]$ <strong class="userinput"><code>cvs -d /var/lib/cvs/ import -m "importing package" <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/<span class="replaceable"><span class="replaceable">myfirstpackage</span></span> OpenACS openacs-5-1</code></strong>
</pre>
</div><p>Create a new directory as temporary working space to reconcile
conflicts between the new files and your current work. The example
uses the cvs keyword yesterday, making the assumption that you
haven't checked in new code to your local tree in the last day.
This section should be improved to use tags instead of the keyword
yesterday!</p><pre class="screen">
[$OPENACS_SERVICE_NAME openacs-5.1]$ <strong class="userinput"><code> cd /var/lib/aolserver</code></strong>
[$OPENACS_SERVICE_NAME tmp]$ <strong class="userinput"><code>rm -rf <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-upgrade</code></strong>
[$OPENACS_SERVICE_NAME tmp]$ <strong class="userinput"><code>mkdir <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-upgrade</code></strong>
[$OPENACS_SERVICE_NAME tmp]$ <strong class="userinput"><code>cvs checkout -d <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-upgrade -jOpenACS:yesterday -jOpenACS -kk <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> &gt; cvs.txt 2&gt;&amp;1</code></strong>
(CVS feedback here)
</pre><p>The file /var/tmp/openacs-upgrade/cvs.txt contains the results
of the upgrade. If you changed files that are part of the OpenACS
tarball and those changes conflict, you'll have to manually
reconcile them. Use the emacs command <code class="computeroutput">M-x sort-lines</code> (you may have to click
Ctrl-space at the beginning of the file, and go to the end, and
then try M-x sort-lines) and then, for each line that starts with a
C, open that file and manually resolve the conflict by deleting the
excess lines. When you're finished, or if there aren't any
conflicts, save and exit.</p><p>Once you've fixed any conflicts, commit the new code to your
local tree.</p><pre class="screen">
[$OPENACS_SERVICE_NAME tmp]$ <strong class="userinput"><code>cd <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-upgrade</code></strong>
[$OPENACS_SERVICE_NAME <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-upgrade]$ <strong class="userinput"><code>cvs commit -m "Upgraded to 5.1"</code></strong>
</pre>
</li><li class="listitem">
<p>
<b>Step 3: Upgrade your local staging
site. </b>Update your working tree with the new files.
The CVS flags ensure that new directories are created and pruned
directories destroyed.</p><pre class="screen">
[$OPENACS_SERVICE_NAME <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-upgrade]$ <strong class="userinput"><code>cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cvs up -Pd</code></strong>
(CVS feedback)
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>exit</code></strong>
[root root]# 
</pre>
</li>
</ul></div>
</li>
</ul></div><p><span class="strong"><strong>Upgrading files for a site using
the OpenACS CVS repository (cvs.openacs.org)</strong></span></p><div class="orderedlist"><ol class="orderedlist" type="1"><li class="listitem"><pre class="screen">
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cvs up -Pd</code></strong>
(CVS feedback)
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$
</pre></li></ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140480063233888" id="idp140480063233888"></a>Upgrading a Production Site Safely</h3></div></div></div><p>If you are upgrading a production OpenACS site which is on a
private CVS tree, this process lets you do the upgrade without
risking extended downtime or an unusable site:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Declare a freeze on new cvs updates - ie, you cannot run cvs
update on the production site</p></li><li class="listitem"><p>Make a manual backup of the production site in addition to the
automated backups</p></li><li class="listitem">
<p>Import the new code (for example, OpenACS 5.0.4,
openacs-5-0-compat versions of ETP, blogger, and other
applications) into a "vendor branch" of the <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> CVS tree, as
described in "Upgrading a local CVS repository", step 1, above. As
soon as we do this, any cvs update command on production might
bring new code onto the production site, which would be bad.</p><p>Do step 2 above (merging conflicts in a <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-upgrade working
tree).</p>
</li><li class="listitem"><p>Manually resolve any conflicts in the working upgrade tree</p></li><li class="listitem"><p>Use the upgrade script and a recent backup of the production
database, to ake a new upgraded database called <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-upgrade. Now we
have a new website called <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-upgrade.</p></li><li class="listitem"><p>Test the <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-upgrade site</p></li><li class="listitem">
<p>If <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-upgrade is fully
functional, do the real upgrade.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Take down the <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> site and put up a
"down for maintenance" page.</p></li><li class="listitem"><p>Repeat the upgrade with the most recent database</p></li><li class="listitem"><p>Test the that the new site is functional. If so, change the
upgraded site to respond to <span class="replaceable"><span class="replaceable">yourserver.net</span></span> requests. If not, bring
the original production site back up and return to the merge.</p></li>
</ol></div>
</li>
</ol></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="upgrade-5-0-dot" leftLabel="Prev" leftTitle="Upgrading an OpenACS 5.0.0 or greater
installation"
		    rightLink="upgrade-supporting" rightLabel="Next" rightTitle="Upgrading Platform components"
		    homeLink="index" homeLabel="Home" 
		    upLink="upgrade" upLabel="Up"> 
		