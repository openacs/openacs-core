
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {OpenACS Core and .LRN}</property>
<property name="doc(title)">OpenACS Core and .LRN</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="releasing-openacs" leftLabel="Prev"
		    title="
Chapter 16. Releasing OpenACS"
		    rightLink="update-repository" rightLabel="Next">
		<div class="section">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="releasing-openacs-core" id="releasing-openacs-core"></a>OpenACS
Core and .LRN</h2></div></div></div><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<strong>Update Translations. </strong><a class="xref" href="update-translations" title="How to Update the translations">the section called
&ldquo;How to Update the
translations&rdquo;</a>
</p></li><li class="listitem">
<p>
<strong>Rebuild the Changelog. </strong>Rebuild the
Changelog. I use a tool called cvs2cl. Run this command from the
package root to automatically generate a Changelog file in the same
dir. We generate two changelogs, one for the minor branch and one
for the most recent release. The example below is for OpenACS
5.0.2:</p><pre class="screen"><span class="action"><span class="action">cd /var/lib/aolserver/$OPENACS_SERVICE_NAME
cvs2cl -F <span class="replaceable"><span class="replaceable">oacs-5-0</span></span> --delta <span class="replaceable"><span class="replaceable">openacs-5-0-0-final</span></span>:<span class="replaceable"><span class="replaceable">oacs-5-0</span></span> -f ChangeLog
cvs2cl -F <span class="replaceable"><span class="replaceable">oacs-5-0</span></span> --delta <span class="replaceable"><span class="replaceable">openacs-5-0-1-final</span></span>:<span class="replaceable"><span class="replaceable">oacs-5-0</span></span> -f ChangeLog-recent</span></span></pre>
</li><li class="listitem">
<p>
<strong>Update Version Numbers. </strong>The version
numbers in the documentation and in the packages must be updated.
This should only happen after a release candidate is approved.</p><p class="remark"><em><span class="remark">.LRN: this must be
repeated for .LRN modules (dotlrn-core in the dotlrn cvs tree) and
for any modified modules in the .LRN prerequisites (dotlrn-prereq
in OpenACS cvs tree). My current working model is that I
bulk-update .LRN and OpenACS core but that I don&#39;t touch
dotlrn-prereq modules - I just use the most recent release and
it&#39;s up to individual package developers to tag and <a class="link" href="releasing-package" title="How to package and release an OpenACS Package">release those
packages</a> when they change. This model is already broken because
following it means that dotlrn-prereqs don&#39;t get new
translations.</span></em></p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Update
/var/lib/aolserver/$OPENACS_SERVICE_NAME/packages/acs-core-docs/www/xml/variables.ent
with the new version number.</p></li><li class="listitem"><p>Add new section in
/var/lib/aolserver/$OPENACS_SERVICE_NAME/packages/acs-core-docs/www/xml/for-everyone/release-notes.xml</p></li><li class="listitem">
<p>Regenerate all HTML docs</p><pre class="screen">
cd /var/lib/aolserver/$OPENACS_SERVICE_NAME/packages/acs-core-docs/www/xml
make
</pre>
</li><li class="listitem"><p>Update /var/lib/aolserver/$OPENACS_SERVICE_NAME/readme.txt with
the new version number</p></li><li class="listitem">
<p>Update version number and release date in all of the core
packages. Use
/var/lib/aolserver/$OPENACS_SERVICE_NAME/packages/acs-core-docs/www/files/update-info.sh
with the new version number and the release date as arguments. Run
it from /var/lib/aolserver/$OPENACS_SERVICE_NAME/packages:</p><pre class="screen">
cd /var/lib/aolserver/$OPENACS_SERVICE_NAME/packages
       ./acs-core-docs/www/files/update-info <span class="replaceable"><span class="replaceable">5.2.1</span></span><span class="replaceable"><span class="replaceable">2006-01-16</span></span>
</pre>
</li><li class="listitem"><p>Install a new site using the modified code and verify that the
automated tests pass.</p></li><li class="listitem"><p>Commit changes to CVS</p></li>
</ol></div>
</li><li class="listitem">
<p>
<strong>Tag the files in CVS. </strong>The steps to
this point should have ensured that the head of the current branch
contains the full set of code to release. Now we need to tag it as
the code to be released.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem">
<p>Check out OpenACS Core. The files must be checked out through a
cvs account with write access and should be a checkout from the
release branch. In this example, we are assuming this is being done
as a local user on openacs.org (which make the checkout and tagging
operations much faster).</p><pre class="screen"><span class="action"><span class="action">cd /var/tmp
cvs -d /cvsroot checkout -r <span class="replaceable"><span class="replaceable">oacs-5-0</span></span> acs-core</span></span></pre><p>If doing .LRN, repeat with the dotlrn cvs tree.</p><pre class="screen"><span class="action"><span class="action">cd /var/tmp
mkdir dotlrn-packages
cd dotlrn-packages
cvs -d /dotlrn-cvsroot checkout -r <span class="replaceable"><span class="replaceable">dotlrn-2-0</span></span> dotlrn-all
</span></span></pre>
</li><li class="listitem">
<p>Tag the tree. If it&#39;s a final release of core, move or
create the appropriate openacs-major-minor-compat tag. (Ie, if
releasing 5.0.3 final, move the openacs-5-0-compat flag.)</p><pre class="screen"><span class="action"><span class="action">cd /var/tmp/openacs-4
cvs tag -F <span class="replaceable"><span class="replaceable">openacs-5-0-0a1</span></span>
cvs tag -F <span class="replaceable"><span class="replaceable">openacs-5-0-compat</span></span>
</span></span></pre><div class="tip" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">Branching</h3><p>When we feature-freeze on HEAD as part of the release process,
we are blocking new development. To avoid this, we branch the code
at this point, so that new work can continue on HEAD while the
branch is stabilized for release. However, branching means that bug
fixes have to be synchronized between HEAD and the branch, and bug
fixes tend to be more frequent right at this time. Therefore, our
actual branch point is as late as possible - essentially, we do not
branch until and unless new feature work is actively blocked by the
feature freeze. Branching is almost the same as tagging, except for
the flag and slightly different tag nomenclature. To see the list
of old branches, <code class="computeroutput">cvs status -v
somefile</code>.</p><pre class="screen">
cvs tag -b <span class="replaceable"><span class="replaceable">oacs-5-0</span></span>
</pre>
</div><p>If doing .LRN: Since the .LRN packages aren&#39;t all in one
module, we iterate through all of the modules. Log in first (cvs
login) so that you don&#39;t have to log in for each module.</p><pre class="screen"><span class="action"><span class="action">cd /var/tmp/dotlrn-packages
for dir in *; do ( cd $dir &amp;&amp; cvs tag <span class="replaceable"><span class="replaceable">dotlrn-2-0-2-final</span></span> ); done
for dir in *; do ( cd $dir &amp;&amp; cvs tag -F <span class="replaceable"><span class="replaceable">openacs-5-0-compat</span></span> ); done
</span></span></pre><p>Note that for the compat tag we use the <span class="action"><span class="action">-F</span></span> flag which will
force the tag to the new version (just in case someone has created
the tag already on another version). Exercise care when doing this
since you don&#39;t want to inadvertently move a prior release tag.
Also if the tagging goes horribly wrong for some reason you can
delete the tag via <span class="command"><strong>cvs tag -d
&lt;symbolic_tag&gt;</strong></span>.</p>
</li><li class="listitem">
<p>Apply the <code class="computeroutput">final</code> tag across
the tree. First, check out the entire OpenACS tree, getting the
most recent stable version of each package. This is most simply
done on openacs.org:</p><pre class="screen"><span class="action"><span class="action">cd /var/tmp
cvs -d /cvsroot checkout -r <span class="replaceable"><span class="replaceable">openacs-5-1-compat</span></span> openacs-4
cd openacs-4
cvs tag <span class="replaceable"><span class="replaceable">openacs-5-1-2-final</span></span>
</span></span></pre>
</li>
</ol></div>
</li><li class="listitem">
<p><strong>Make the tarball(s). </strong></p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p><strong>openacs-core. </strong></p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem">
<p>Go to a new working space and export the tagged files.</p><pre class="screen"><span class="action"><span class="action">mkdir /var/tmp/tarball
cd /var/tmp/tarball
cvs -d /cvsroot export -r <span class="replaceable"><span class="replaceable">openacs-5-0-0a1</span></span> acs-core</span></span></pre>
</li><li class="listitem">
<p>Generate the tarball.</p><pre class="screen"><span class="action"><span class="action">cd /var/tmp/tarball
mv openacs-4 openacs-<span class="replaceable"><span class="replaceable">5.0.0a1</span></span>
tar cz -f <span class="replaceable"><span class="replaceable">openacs-5.0.0a1.tar.gz</span></span> openacs-<span class="replaceable"><span class="replaceable">5.0.0a1</span></span>
</span></span></pre>
</li>
</ol></div>
</li><li class="listitem">
<p><strong>dotlrn. </strong></p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem">
<p>Go to a new working space and export the tagged files. (was
getting errors here trying to use -d, so gave up and just moved
things from openacs-4 to OpenACS at the end)</p><pre class="screen"><span class="action"><span class="action">mkdir /var/tmp/dotlrn-tarball
cd /var/tmp/dotlrn-tarball
cvs -d /cvsroot export -r <span class="replaceable"><span class="replaceable">openacs-5-0-0a1</span></span> acs-core
cd /var/tmp/dotlrn-tarball/openacs-4/packages
cvs -d /cvsroot export -r <span class="replaceable"><span class="replaceable">openacs-5-0-0a1</span></span> dotlrn-prereq
cvs -d /dotlrn-cvsroot export -r <span class="replaceable"><span class="replaceable">dotlrn-2-0-0a1</span></span> dotlrn-core
</span></span></pre>
</li><li class="listitem">
<p>Copy the dotlrn install.xml file, which controls which packages
are installed on setup, to the root location:</p><pre class="screen"><span class="action"><span class="action">cp /var/tmp/dotlrn-tarball/openacs-4/packages/dotlrn/install.xml \
   /var/tmp/dotlrn-tarball/openacs-4
</span></span></pre>
</li><li class="listitem">
<p>Generate the tarball</p><pre class="screen"><span class="action"><span class="action">cd /var/tmp/dotlrn-tarball
mv openacs-4 dotlrn-<span class="replaceable"><span class="replaceable">2.0.0a1</span></span>
tar cz -f <span class="replaceable"><span class="replaceable">dotlrn-2.0.0a1.tar.gz</span></span> dotlrn-<span class="replaceable"><span class="replaceable">2.0.0a1</span></span>
</span></span></pre>
</li>
</ol></div>
</li>
</ul></div>
</li><li class="listitem"><p>
<strong>Test the new tarball(s). </strong>Download
the tarballs just created and install them and make sure everything
looks okay and that automated tests pass.</p></li><li class="listitem">
<p>
<strong>Update Web site. </strong>Update the
different places on OpenACS.org where we track status.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Release Status for the current version - something like
http://openacs.org/projects/openacs/5.0/milestones</p></li><li class="listitem"><p>Home page of openacs.org</p></li><li class="listitem"><p>Post a new news item</p></li>
</ul></div>
</li><li class="listitem">
<p>
<strong>Clean Up. </strong>Clean up after
yourself.</p><pre class="screen"><span class="action"><span class="action">cd /var/tmp
rm -rf tarball dotlrn-tarball dotlrn-packages openacs-<span class="replaceable"><span class="replaceable">5.0.0a1</span></span>
rm -rf /var/tmp/openacs-4</span></span></pre>
</li>
</ol></div><p>Here is a shell script that automates packaging the tarball
(it&#39;s a bit out of date with the new steps - I&#39;ve been
doing everything manually or with little throwaway scripts as
detailed above until the process is stabilized).</p><pre class="programlisting">
#!/bin/bash

# if TAG=1 create the cvs tags otherwise assume they exist.
TAG=1

# What release version are we building; version format should be
# dashes rather than dots eg. OACS_VERSION=5-0-0b4

OACS_VERSION=5-0-0b4
DOTLRN_VERSION=2-0-0b4

OACS_BRANCH=oacs-5-0
DOTLRN_BRANCH=dotlrn-2-0

DOTLRN_CVSROOT=/dotlrn-cvsroot
OACS_CVSROOT=/cvsroot

#
# Nothing below here should need to change...
#
BASE=/var/tmp/release-$OACS_VERSION
mkdir $BASE
if [ ! -d $BASE ]; then 
    echo "Failed creating base dir $BASE"
    exit 1
fi

cd $BASE 

if [ $TAG -eq 1 ]; then 

    # Checkout and tag the release 
    cvs -d $OACS_CVSROOT checkout -r $OACS_BRANCH openacs-4
    cd openacs-4 
    cvs tag -F openacs-$OACS_VERSION 
    cd ../


    # Checkout and tag the dotlrn release
    mkdir dotlrn-packages
    cd dotlrn-packages
    cvs -d $DOTLRN_CVSROOT checkout -r $DOTLRN_BRANCH dotlrn-all
    for dir in *; do ( cd $dir &amp;&amp; cvs tag -F dotlrn-$DOTLRN_VERSION ); done
    cd ../

    #
    # Should check for .sql .xql .adp .tcl .html .xml executable files and squak if found.
    #

fi



# Generate tarballs...
#

# openacs
#
mkdir tarball
cd tarball
cvs -d $OACS_CVSROOT export -r openacs-$OACS_VERSION acs-core
mv opeancs-4 openacs-${OACS_VERSION//-/.}
tar -czf ../openacs-${OACS_VERSION//-/.}.tar.gz openacs-${OACS_VERSION//-/.}
cd ..

# dotlrn
#
mkdir dotlrn-tarball
cd dotlrn-tarball
cvs -d $OACS_CVSROOT export -r openacs-$OACS_VERSION acs-core
cd  openacs-4/packages
cvs -d $OACS_CVSROOT export -r openacs-$OACS_VERSION dotlrn-prereq
cvs -d $DOTLRN_CVSROOT export -r dotlrn-$DOTLRN_VERSION dotlrn-core
cd ../..
cp -f openacs-4/packages/dotlrn/install.xml openacs-4
mv openacs-4 dotlrn-${DOTLRN_VERSION//-/.}
tar -czf ../dotlrn-${DOTLRN_VERSION//-/.}.tar.gz dotlrn-${DOTLRN_VERSION//-/.}


# Clean up after ourselves...
cd $BASE &amp;&amp; rm -rf dotlrn-tarball tarball openacs-4 dotlrn-packages
</pre><div class="cvstag">($&zwnj;Id: releasing-openacs.xml,v 1.22.2.5
2017/04/22 17:18:48 gustafn Exp $)</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="releasing-openacs" leftLabel="Prev" leftTitle="
Chapter 16. Releasing OpenACS"
		    rightLink="update-repository" rightLabel="Next" rightTitle="How to Update the OpenACS.org
repository"
		    homeLink="index" homeLabel="Home" 
		    upLink="releasing-openacs" upLabel="Up"> 
		