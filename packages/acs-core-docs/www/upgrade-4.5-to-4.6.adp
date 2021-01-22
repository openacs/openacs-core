
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Upgrading 4.5 or higher to 4.6.3}</property>
<property name="doc(title)">Upgrading 4.5 or higher to 4.6.3</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="upgrade-overview" leftLabel="Prev"
		    title="
Chapter 5. Upgrading"
		    rightLink="upgrade-4.6.3-to-5" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="upgrade-4.5-to-4.6" id="upgrade-4.5-to-4.6"></a>Upgrading 4.5 or higher to 4.6.3</h2></div></div></div><a class="indexterm" name="idp140592104583224" id="idp140592104583224"></a><p>The required platform for OpenACS 4.6 is the same as 4.5, with
the exception of OpenFTS. OpenACS 4.6 and later require OpenFTS
0.3.2 for full text search on PostGreSQL. If you have OpenFTS 0.2,
you&#39;ll need to upgrade.</p><p>If upgrading from 4.4, you need to manually run
acs-kernel/sql/postgres/upgrade-4.4-4.5.sql. See <a class="ulink" href="http://openacs.org/bugtracker/openacs/bug?bug_number=632" target="_top">Bug #632</a>
</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem" style="list-style-type: circle"><p>A computer with OpenACS 4.5.</p></li><li class="listitem" style="list-style-type: circle"><p>
<a class="ulink" href="http://openacs.org/projects/openacs/download/" target="_top">OpenACS 4.6 tarball</a> or CVS checkout/export.</p></li><li class="listitem" style="list-style-type: circle"><p>Required for Full Text Search on PostgreSQL: <a class="ulink" href="http://openfts.sourceforge.net" target="_top">OpenFTS
0.3.2</a>
</p></li>
</ul></div><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<strong>Make a Backup. </strong>Back up the database
and file system (see <a class="xref" href="snapshot-backup" title="Manual backup and recovery">the section called
&ldquo;Manual backup and
recovery&rdquo;</a>).</p></li><li class="listitem"><p>
<strong>OPTIONAL: Upgrade
OpenFTS. </strong><a class="xref" href="upgrade-supporting" title="Upgrading OpenFTS from 0.2 to 0.3.2">the section called
&ldquo;Upgrading OpenFTS from 0.2 to
0.3.2&rdquo;</a>
</p></li><li class="listitem">
<p>Stop the server</p><pre class="screen">
[root root]# <strong class="userinput"><code>svc -d /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
</pre>
</li><li class="listitem"><p>
<strong>Upgrade the file system. </strong><a class="xref" href="upgrade-openacs-files" title="Upgrading the OpenACS files">the section called
&ldquo;Upgrading the OpenACS
files&rdquo;</a>
</p></li><li class="listitem">
<p><span class="strong"><strong>Start the
server</strong></span></p><pre class="screen">
[root root]# <strong class="userinput"><code>svc -u /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
</pre>
</li><li class="listitem">
<p>
<a name="upgrade-with-apm" id="upgrade-with-apm"></a><strong>Use
APM to upgrade the database. </strong>
</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Browse to the package manager, <code class="computeroutput">http://<span class="replaceable"><span class="replaceable">yourserver</span></span>/acs-admin/apm</code>.</p></li><li class="listitem"><p>Click <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install
packages.</span></span></code>
</p></li><li class="listitem"><p>Select the packages you want to install. This should be
everything that says <code class="computeroutput">upgrade</code>,
plus any new packages you want. It&#39;s safest to upgrade the
kernel by itself, and then come back and upgrade the rest of the
desired packages in a second pass.</p></li><li class="listitem"><p>On the next screen, click <code class="computeroutput"><span class="guibutton"><span class="guibutton">Install Packages</span></span></code>
</p></li><li class="listitem">
<p>When prompted, restart the server:</p><pre class="screen">
[root root]# <strong class="userinput"><code>restart-aolserver <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
</pre>
</li><li class="listitem"><p>Wait a minute, then browse to the package manager, <code class="computeroutput">http://<span class="replaceable"><span class="replaceable">yourserver</span></span>/acs-admin/apm</code>.</p></li><li class="listitem"><p>Check that the kernel upgrade worked by clicking <code class="computeroutput"><span class="guilabel"><span class="guilabel">All</span></span></code> and making sure that
<code class="computeroutput">acs-kernel</code> version is
5.9.0.</p></li>
</ol></div>
</li><li class="listitem"><p>
<strong>Rollback. </strong>If anything goes wrong,
<a class="link" href="snapshot-backup" title="Recovery">roll back</a> to the backup snapshot.</p></li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="upgrade-overview" leftLabel="Prev" leftTitle="Overview"
		    rightLink="upgrade-4.6.3-to-5" rightLabel="Next" rightTitle="Upgrading OpenACS 4.6.3 to 5.0"
		    homeLink="index" homeLabel="Home" 
		    upLink="upgrade" upLabel="Up"> 
		