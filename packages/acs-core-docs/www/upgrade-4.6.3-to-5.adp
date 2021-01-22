
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Upgrading OpenACS 4.6.3 to 5.0}</property>
<property name="doc(title)">Upgrading OpenACS 4.6.3 to 5.0</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="upgrade-4.5-to-4.6" leftLabel="Prev"
		    title="
Chapter 5. Upgrading"
		    rightLink="upgrade-5-0-dot" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="upgrade-4.6.3-to-5" id="upgrade-4.6.3-to-5"></a>Upgrading OpenACS 4.6.3 to 5.0</h2></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<strong>Oracle. </strong>This forum posting
documents <a class="ulink" href="http://openacs.org/forums/message-view?message_id=201394" target="_top">how to upgrade an Oracle installation from OpenACS 4.6.3 to
5</a> .</p></li><li class="listitem">
<p>
<strong>PostGreSQL. </strong>You must use PostGreSQL
7.3.x or newer to upgrade OpenACS beyond 4.6.3. See <a class="link" href="upgrade-supporting" title="Upgrading from PostGreSQL 7.2 to 7.3">Upgrade PostGreSQL to
7.3</a>; <a class="xref" href="individual-programs" title="Table 2.2. Version Compatibility Matrix">Table 2.2,
&ldquo;Version Compatibility
Matrix&rdquo;</a>
</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p><a class="link" href="snapshot-backup" title="Manual backup and recovery">Back up the database and file
system.</a></p></li><li class="listitem"><p>
<strong>Upgrade the file system for
packages/acs-kernel. </strong><a class="xref" href="upgrade-openacs-files" title="Upgrading the OpenACS files">the section called
&ldquo;Upgrading the OpenACS
files&rdquo;</a>
</p></li><li class="listitem">
<p>Upgrade the kernel manually. (There is a script to do most of
the rest: <a class="ulink" href="http://cvs.openacs.org/browse/OpenACS/openacs-4/contrib/misc/upgrade_4.6_to_5.0.sh?r=1.6" target="_top">/contrib/misc/upgrade_4.6_to_5.0.sh on HEAD</a>).
You&#39;ll still have to do a lot of stuff manually, but automated
trial and error is much more fun.)</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cd /var/lib/aolserver/ <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/acs-kernel/sql/postgresql/upgrade</code></strong>
</pre><p>Manually execute each of the upgrade scripts in sequence, either
from within psql or from the command line with commands such as
<code class="computeroutput"><strong class="userinput"><code>psql
-f upgrade-4.6.3-4.6.4.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong></code>.
Run the scripts in this order (order is tentative, not
verified):</p><pre class="programlisting">
psql -f upgrade-4.6.3-4.6.4.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-4.6.4-4.6.5.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-4.6.5-4.6.6.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-4.7d-4.7.2d.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-4.7.2d-5.0d.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-5.0d-5.0d2.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-5.0d2-5.0d3.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-5.0d6-5.0d7.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-5.0d7-5.0d9.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-5.0d11-5.0d12.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-5.0.0a4-5.0.0a5.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-5.0.0b1-5.0.0b2.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-5.0.0b2-5.0.0b3.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql -f upgrade-5.0.0b3-5.0.0b4.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</pre>
</li><li class="listitem">
<p>Upgrade ACS Service Contracts manually:</p><pre class="screen">
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cd /var/lib/aolserver/ <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/acs-service-contracts/sql/postgresql/upgrade</code></strong>
psql -f upgrade-4.7d2-4.7d3.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</pre>
</li><li class="listitem">
<p>Load acs-authentication data model.</p><pre class="screen"><strong class="userinput"><code>psql -f /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/openacs-5/packages/acs-authentication/sql/postgresql/acs-authentication-create.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong></pre>
</li><li class="listitem">
<p>Load acs-lang data model.</p><pre class="screen"><strong class="userinput"><code>psql -f /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/acs-lang/sql/postgresql/acs-lang-create.sql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong></pre>
</li><li class="listitem">
<p>(This step may overlap with the two previous steps, but I think
it&#39;s harmless?) Create a file which will be executed on startup
which takes care of a few issues with authentication and
internationalization: create <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/tcl/zzz-postload.tcl
containing:</p><pre class="programlisting">
if {![apm_package_installed_p acs-lang]} {
apm_package_install -enable -mount_path acs-lang $::acs::rootdir/packages/acs-lang/acs-lang.info
lang::catalog::import -locales [list "en_US"]
}

if {![apm_package_installed_p acs-authentication]} {
apm_package_install -enable $::acs::rootdir/packages/acs-authentication/acs-authentication.info
apm_parameter_register "UsePasswordWidgetForUsername" \
"Should we hide what the user types in the username
field, the way we do with the password field? Set
this to 1 if you are using sensitive information
such as social security number for username." \
acs-kernel 0 number \
security 1 1
parameter::set_value -package_id [ad_acs_kernel_id] -parameter UsePasswordWidgetForUsername -value 0
}
</pre>
</li><li class="listitem"><p>If you can login, visit /acs-admin/apm and upgrade acs-kernel
and acs-service-contract and uncheck the data model scripts.
Restart. If everything is still working, make another backup of the
database.</p></li><li class="listitem"><p>Upgrade other packages <a class="link" href="upgrade-4.5-to-4.6" title="Use APM to upgrade the database">via the APM</a>
</p></li>
</ol></div><p>See also these forum posts: <a class="ulink" href="http://openacs.org/forums/message-view?message_id=143497" target="_top">Forum OpenACS Development: 4.6.3 upgrade to 5-HEAD: final
results</a>, <a class="ulink" href="http://openacs.org/forums/message-view?message_id=152200" target="_top">OpenACS 5.0 Upgrade Experiences</a>.</p><p>There are a few things you might want to do once you&#39;ve
upgraded. First, the acs-kernel parameters need to be set to allow
HREF and IMG tags, if you want users who can edit HTML to be able
to insert HREF and IMG tags. Also, you might need to set the
default language for your site. See the above link on OpenACS 5.0
Upgrade Experiences for details.</p>
</li>
</ul></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="upgrade-4.5-to-4.6" leftLabel="Prev" leftTitle="Upgrading 4.5 or higher to 4.6.3"
		    rightLink="upgrade-5-0-dot" rightLabel="Next" rightTitle="Upgrading an OpenACS 5.0.0 or greater
installation"
		    homeLink="index" homeLabel="Home" 
		    upLink="upgrade" upLabel="Up"> 
		