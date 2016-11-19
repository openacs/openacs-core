
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {How to Update the OpenACS.org repository}</property>
<property name="doc(title)">How to Update the OpenACS.org repository</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="releasing-openacs-core" leftLabel="Prev"
		    title="
Chapter 16. Releasing OpenACS"
		    rightLink="releasing-package" rightLabel="Next">
		<div class="section">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="update-repository" id="update-repository"></a>How to Update the OpenACS.org
repository</h2></div></div></div><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Setup a local OpenACS server running 5.0 or better.</p></li><li class="listitem"><p>Edit <code class="computeroutput">packages/acs-admin/www/apm/build-repository.tcl</code>
and adjust the Configuration Settings.</p></li><li class="listitem"><p>Request /acs-admin/apm/build-repository on your new server.</p></li><li class="listitem"><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>The page will find all branches in the cvs repository labeled
oacs-x-y, and build a repository channel for each of those branches
where x&gt;=5 (so not for 4.6 and earlier). It will also build a
channel for HEAD, which will be named after what you set in
'head_channel' above.</p></li><li class="listitem"><p>For each channel, it&#39;ll do an anonymous checkout of packges
and contrib/packages, then build .apm files for each package in the
checkout.</p></li><li class="listitem"><p>The files will be stored on the server&#39;s hard drive in the
directory specified by the 'repository_dir' variable in the
page script, by default
"$::acs::rootdir/www/repository/".</p></li>
</ol></div></li><li class="listitem">
<p>If you&#39;re on openacs.org, everything should now be fine.
Otherwise, you need to move the entire directory tree to
openacs.org:/web/openacs/www/repository, replacing what was already
there.</p><p>This is automated on OpenACS.org by having a dedicated site just
for building the repository, invoked with this shell script. Since
the page circumvents security checks for ease of use, the entire
site is limited to local requests. The script is called daily with
a cron job.</p><pre class="programlisting">
#!/bin/sh
#set -x

STATUS=`wget --output-document - http://127.0.0.1:8002/build-repository.tcl | grep DONE | wc -l`

if [ $STATUS -eq "1" ]
then
    rm -rf /web/openacs.org/www/repository.old
    mv /web/openacs.org/www/repository /web/openacs.org/www/repository.old
    cp -r /web/repository/www/repository /web/openacs.org/www/repository
fi
</pre>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="releasing-openacs-core" leftLabel="Prev" leftTitle="OpenACS Core and .LRN"
		    rightLink="releasing-package" rightLabel="Next" rightTitle="How to package and release an OpenACS
Package"
		    homeLink="index" homeLabel="Home" 
		    upLink="releasing-openacs" upLabel="Up"> 
		