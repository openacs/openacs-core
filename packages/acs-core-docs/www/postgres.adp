
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install PostgreSQL}</property>
<property name="doc(title)">Install PostgreSQL</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="oracle" leftLabel="Prev"
			title="Chapter 3. Complete
Installation"
			rightLink="aolserver4" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="postgres" id="postgres"></a>Install PostgreSQL</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">by <a class="ulink" href="mailto:vinod\@kurup.com" target="_top">Vinod Kurup</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><p>Skip this section if you will run only Oracle.</p><p>OpenACS 5.9.0 will run with <a class="link" href="individual-programs" title="PostgreSQL 7.4.x (Either this or Oracle is REQUIRED)">PostgreSQL</a>
9.0 or newer. 9.5 is currently the recommended version of
PostgreSQL.</p><p>It is recommend to use a prepackaged version of PostgreSQL,
which are available in source and binary formats from <a class="ulink" href="https://www.postgresql.org/download" target="_top">www.postgresql.org/download/</a>.</p><p>Larger installations might want to tune the PostgreSQL
installation with e.g. the utility <a class="ulink" href="https://github.com/gregs1104/pgtune" target="_top">pgtune</a>,
which is also available via <strong class="userinput"><code>apt-get
install pgtune</code></strong> or <strong class="userinput"><code>dnf install pgtune</code></strong> on
Debian/Ubuntu or RedHat systems.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-postgres-moreinfo" id="install-postgres-moreinfo"></a>More information about
PostgreSQL</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="ulink" href="https://www.postgresql.org/docs/" target="_top">Official PostgreSQL Docs</a></p></li><li class="listitem"><p><a class="ulink" href="http://www.whoishostingthis.com/resources/postgresql/" target="_top">PostgreSQL Introduction and Resources</a></p></li><li class="listitem"><p><a class="ulink" href="https://wiki.postgresql.org/wiki/Performance_Optimization" target="_top">PostgreSQL Performance Tuning</a></p></li>
</ul></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="oracle" leftLabel="Prev" leftTitle="Install Oracle 8.1.7"
			rightLink="aolserver4" rightLabel="Next" rightTitle="Install AOLserver 4"
			homeLink="index" homeLabel="Home" 
			upLink="complete-install" upLabel="Up"> 
		    