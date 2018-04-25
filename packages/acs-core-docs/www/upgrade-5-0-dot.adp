
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Upgrading an OpenACS 5.0.0 or greater installation}</property>
<property name="doc(title)">Upgrading an OpenACS 5.0.0 or greater installation</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="upgrade-4.6.3-to-5" leftLabel="Prev"
			title="Chapter 5. Upgrading"
			rightLink="upgrade-openacs-files" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="upgrade-5-0-dot" id="upgrade-5-0-dot"></a>Upgrading an OpenACS 5.0.0 or greater
installation</h2></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<strong>Upgrading a stock site. </strong> If you have no
custom code, and your site is not in a CVS repository, upgrade with
these steps:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Go to <a class="ulink" href="/acs-admin/install" target="_top">/acs-admin/install/</a> and click "Upgrade Your
System" in "Install from OpenACS Repository"</p></li><li class="listitem"><p>Select all of the packages you want to upgrade and proceed</p></li><li class="listitem"><p>After upgrade is complete, restart the server as indicated.</p></li><li class="listitem"><p>If you are using locales other than en_US, go to acs-lang/admin
and "Import all Messages" to load the new translated
messages. Your local translations, if any, will take precedence
over imported translations.</p></li>
</ol></div>
</li><li class="listitem">
<p>
<strong>Upgrading a Custom or CVS site. </strong> If you
have custom code, and your site is in a CVS repository, upgrade
with these steps:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<strong>Upgrade the file system for all packages in
use. </strong><a class="xref" href="upgrade-openacs-files" title="Upgrading the OpenACS files">the section called “Upgrading the
OpenACS files”</a>
</p></li><li class="listitem"><p>Go to <a class="ulink" href="/acs-admin/install" target="_top">/acs-admin/install/</a> and click "Upgrade Your
System" in "Install from local file system"</p></li><li class="listitem"><p>Select all of the packages you want to upgrade and proceed</p></li><li class="listitem"><p>After upgrade is complete, restart the server as indicated.</p></li><li class="listitem"><p>If you are using locales other than en_US, go to acs-lang/admin
and "Import all Messages" to load the new translated
messages. Your local translations, if any, will take precedence
over imported translations.</p></li>
</ol></div>
</li>
</ul></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="upgrade-4.6.3-to-5" leftLabel="Prev" leftTitle="Upgrading OpenACS 4.6.3 to 5.0"
			rightLink="upgrade-openacs-files" rightLabel="Next" rightTitle="Upgrading the OpenACS files"
			homeLink="index" homeLabel="Home" 
			upLink="upgrade" upLabel="Up"> 
		    