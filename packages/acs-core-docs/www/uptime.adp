
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {External uptime validation}</property>
<property name="doc(title)">External uptime validation</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="analog-setup" leftLabel="Prev"
			title="Chapter 6. Production
Environments"
			rightLink="maint-performance" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="uptime" id="uptime"></a>External uptime validation</h2></div></div></div><p>The <a class="ulink" href="http://uptime.openacs.org/uptime/" target="_top">OpenACS uptime site</a> can monitor your site and
send you an email whenever your site fails to respond. If you test
the url <code class="computeroutput">http://<em class="replaceable"><code>yourserver.test</code></em>/SYSTEM/dbtest.tcl</code>,
you should get back the string <code class="computeroutput">success</code>.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="analog-setup" leftLabel="Prev" leftTitle="Set up Log Analysis Reports"
			rightLink="maint-performance" rightLabel="Next" rightTitle="Diagnosing Performance Problems"
			homeLink="index" homeLabel="Home" 
			upLink="maintenance-web" upLabel="Up"> 
		    