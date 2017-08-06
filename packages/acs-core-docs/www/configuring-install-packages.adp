
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Installing OpenACS packages}</property>
<property name="doc(title)">Installing OpenACS packages</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="configuring-new-site" leftLabel="Prev"
		    title="
Chapter 4. Configuring a new OpenACS
Site"
		    rightLink="configuring-mounting-packages" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="configuring-install-packages" id="configuring-install-packages"></a>Installing OpenACS packages</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:jade\@rubick.com" target="_top">Jade Rubick</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140592099246776" id="idp140592099246776"></a>Installing OpenACS packages</h3></div></div></div><p>An OpenACS package extends your website and lets it do things it
wasn&#39;t able to do before. You can have a weblog, a forums, a
calendar, or even do sophisticated project-management via your
website.</p><p>After you&#39;ve installed OpenACS, you can congratulate
yourself for a job well done. Then, you&#39;ll probably want to
install a couple of packages.</p><p>To install packages, you have to be an administrator on the
OpenACS webserver. Log in, and you&#39;ll see a link to Admin or
the Control Panel. Click on that, then click on 'Install
software'. Packages are sometimes also referred to as
applications or software.</p><p>At this point, you&#39;ll need to determine whether or not
you&#39;re able to install from the repository, or whether you
should install from local files.</p><p>Basically, if you have a local CVS repository, or have custom
code, you need to install from 'Local Files'. Otherwise,
you can install from the OpenACS repository</p><p>If you want to install new packages, click on 'Install from
Repository' or 'Install from Local'. Select the
package, and click 'Install checked applications'. The
system will check to make sure you have all necessary packages that
the package you want depends on. If you&#39;re installing from
Local Files, and you are missing any packages, you may have to add
the packages your desired package depends on: <a class="xref" href="upgrade-openacs-files" title="Upgrading the OpenACS files">the section called
&ldquo;Upgrading the OpenACS
files&rdquo;</a>
</p><p>If you run into any errors at all, check your
/var/lib/aolserver/$OPENACS_SERVICE_NAME/log/error.log file, and
post your error on the OpenACS forums</p><p>Once the package has been installed, then you will need to
'mount' the package. The next section handles that.</p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="configuring-new-site" leftLabel="Prev" leftTitle="
Chapter 4. Configuring a new OpenACS
Site"
		    rightLink="configuring-mounting-packages" rightLabel="Next" rightTitle="Mounting OpenACS packages"
		    homeLink="index" homeLabel="Home" 
		    upLink="configuring-new-site" upLabel="Up"> 
		