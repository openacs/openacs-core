
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Mounting OpenACS packages}</property>
<property name="doc(title)">Mounting OpenACS packages</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="configuring-install-packages" leftLabel="Prev"
		    title="
Chapter 4. Configuring a new OpenACS
Site"
		    rightLink="configuring-configuring-packages" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="configuring-mounting-packages" id="configuring-mounting-packages"></a>Mounting OpenACS packages</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:jade\@rubick.com" target="_top">Jade Rubick</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140592104632200" id="idp140592104632200"></a>Mounting OpenACS packages</h3></div></div></div><p>After you&#39;ve installed your packages, you have to
'mount' them in order to make them appear on your
website.</p><p>Make sure you are logged in, and then click on the
'Admin' or 'Control Panel' link to get to the
Site-Wide Administration page (at /acs-admin). Click on the subsite
you&#39;d like the application to be available at.</p><p>Subsites are a way of dividing your website into logical chunks.
Often they represent different groups of users, or parts of an
organization.</p><p>Now click on 'Applications' (applications are the same
thing as packages). You&#39;ll see a list of Applications and the
URLs that each is located at. To mount a new application, you click
on 'Add application', enter the Application, title
(application name), and URL (URL folder name), and you&#39;re
done.</p><p>Test it out now. The URL is based on a combination of the
subsite URL and the application URL. So if you installed a package
in the Main Subsite at the URL calendar, it will be available at
http://www.yoursite.com/calendar. If you installed it at a subsite
that has a URL intranet, then it would be located at
http://www.yoursite.com/intranet/calendar.</p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="configuring-install-packages" leftLabel="Prev" leftTitle="Installing OpenACS packages"
		    rightLink="configuring-configuring-packages" rightLabel="Next" rightTitle="Configuring an OpenACS package"
		    homeLink="index" homeLabel="Home" 
		    upLink="configuring-new-site" upLabel="Up"> 
		