
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {How to package and release an OpenACS Package}</property>
<property name="doc(title)">How to package and release an OpenACS Package</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="update-repository" leftLabel="Prev"
			title="Chapter 16. Releasing
OpenACS"
			rightLink="update-translations" rightLabel="Next">
		    <div class="section">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="releasing-package" id="releasing-package"></a>How to package and release an OpenACS
Package</h2></div></div></div><p>In this example, we are packaging and releasing <code class="computeroutput">myfirstpackage</code> as version 1.0.0, which is
compatible with OpenACS 5.0.x.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Update the version number, release date, and <a class="ulink" href="http://openacs.org/forums/message-view?message_id=161393" target="_top">package maturity</a> of your package in the <a class="ulink" href="/acs-admin/apm/" target="_top">APM</a>.</p></li><li class="listitem"><p>Make sure all changes are committed.</p></li><li class="listitem">
<p>Tag the updated work.:</p><pre class="screen"><span class="action">cd /var/lib/aolserver/$OPENACS_SERVICE_NAME/packages/<em class="replaceable"><code>myfirstpackage</code></em>
cvs tag <em class="replaceable"><code>myfirstpackages-1-0-0-final</code></em>
cvs tag -F <em class="replaceable"><code>openacs-5-0-compat</code></em>
</span></pre>
</li>
</ol></div><p>Done. The package will be added to the <a class="ulink" href="http://openacs.org/repository" target="_top">repository</a>
automatically. If the correct version does not show up within 24
hours, ask for help on the OpenACS.org development forum.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="update-repository" leftLabel="Prev" leftTitle="How to Update the OpenACS.org
repository"
			rightLink="update-translations" rightLabel="Next" rightTitle="How to Update the translations"
			homeLink="index" homeLabel="Home" 
			upLink="releasing-openacs" upLabel="Up"> 
		    