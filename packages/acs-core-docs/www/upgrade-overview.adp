
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Overview}</property>
<property name="doc(title)">Overview</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="upgrade" leftLabel="Prev"
		    title="
Chapter 5. Upgrading"
		    rightLink="upgrade-4.5-to-4.6" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="upgrade-overview" id="upgrade-overview"></a>Overview</h2></div></div></div><p>Starting with Version 4.5, all OpenACS core packages support
automatic upgrade. That means that, if you have OpenACS 4.5 or
better, you should always be able to upgrade all of your core
packages automatically. If you haven&#39;t changed anything, no
manual intervention should be required. If you are running OpenACS
prior to 4.5, upgrading will require manual effort.</p><p>If all of these conditions are true:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Your OpenACS Core is 5.0.0 or later</p></li><li class="listitem"><p>You do not keep your OpenACS site in a local CVS repository</p></li><li class="listitem"><p>You do not have any custom code</p></li>
</ul></div><p>then you can upgrade automatically using the automated installer
in the OpenACS Package Manager (APM), and you can probably skip the
rest of this chapter. To upgrade directly from the OpenACS
repository using the APM:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Browse to the <a class="ulink" href="/acs-admin/install/" target="_top">Installer</a>.</p></li><li class="listitem"><p>Click install or upgrade under "Install from OpenACS
Repository" and select the packages to install or upgrade.</p></li><li class="listitem"><p>The APM will download the requested packages from OpenACS.org,
install the files on your hard drive, run any appropriate database
upgrade scripts, and prompt you to restart the server. After
restarting the server again, the upgrade is complete.</p></li>
</ol></div><div class="figure">
<a name="idp140592104571672" id="idp140592104571672"></a><p class="title"><strong>Figure 5.1. Upgrading with the
APM</strong></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/upgrade-apm.png" align="middle" alt="Upgrading with the APM"></div></div>
</div><br class="figure-break"><p>It&#39;s always a good idea to precede an upgrade attempt with a
<a class="link" href="snapshot-backup" title="Manual backup and recovery">snapshot backup</a>.</p><div class="table">
<a name="idp140592104575352" id="idp140592104575352"></a><p class="title"><strong>Table 5.1. Assumptions in this
section</strong></p><div class="table-contents"><table class="table" summary="Assumptions in this section" cellspacing="0" border="1">
<colgroup>
<col><col>
</colgroup><tbody>
<tr>
<td>name of OpenACS user</td><td><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></td>
</tr><tr>
<td>OpenACS server name</td><td><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></td>
</tr><tr>
<td>Root of OpenACS file tree</td><td><span class="replaceable"><span class="replaceable">/var/lib/aolserver/$OPENACS_SERVICE_NAME</span></span></td>
</tr><tr>
<td>Database backup directory</td><td><span class="replaceable"><span class="replaceable">/var/lib/aolserver/$OPENACS_SERVICE_NAME/database-backup</span></span></td>
</tr>
</tbody>
</table></div>
</div><br class="table-break">
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="upgrade" leftLabel="Prev" leftTitle="
Chapter 5. Upgrading"
		    rightLink="upgrade-4.5-to-4.6" rightLabel="Next" rightTitle="Upgrading 4.5 or higher to 4.6.3"
		    homeLink="index" homeLabel="Home" 
		    upLink="upgrade" upLabel="Up"> 
		