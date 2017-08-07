
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {How to Update the translations}</property>
<property name="doc(title)">How to Update the translations</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="releasing-package" leftLabel="Prev"
		    title="
Chapter 16. Releasing OpenACS"
		    rightLink="ix01" rightLabel="Next">
		<div class="section">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="update-translations" id="update-translations"></a>How to Update the translations</h2></div></div></div><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>Identify any new locales that have been created. For each new
locale, check the parameters, especially that the locale is in the
format <span class="emphasis"><em>[two-letter code for language,
lower-case]_[TWO-LETTER CODE FOR COUNTRY, UPPER-CASE]</em></span>,
and create a sql command. A example sql command for creating a
locale is:</p><pre class="programlisting">
insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
       values ('fa_IR', 'Farsi (IR)', 'fa', 'IR', 'FARSI', 'IRAN', 'AL24UTFFSS', 
        'windows-1256', 't', 'f');
</pre><p>Put this command into the following four files. For the upgrade
files, the correct file name will depend on the exact version.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><code class="computeroutput">/packages/acs-lang/sql/postgresql/ad-locales.sql</code></p></li><li class="listitem"><p><code class="computeroutput">/packages/acs-lang/sql/postgresql/upgrade/upgrade-<span class="replaceable"><span class="replaceable">current-version</span></span>.sql</code></p></li><li class="listitem"><p><code class="computeroutput">/packages/acs-lang/sql/oracle/ad-locales.sql</code></p></li><li class="listitem"><p><code class="computeroutput">/packages/acs-lang/sql/oracle/upgrade/upgrade-<span class="replaceable"><span class="replaceable">current-version</span></span>.sql</code></p></li>
</ul></div>
</li><li class="listitem"><p>Make a backup of the production database. Restore it as a new
database. For example, if upgrading from OpenACS 5.1.1, and the
site name/database name is translate-511, create
translate-512b1.</p></li><li class="listitem">
<p>Check out the latest code on the release branch (e.g., oacs-5-1)
as a new site, using the new site name (e.g.,
/var/lib/aolserver/translate-512b1. Copy over any local settings -
usually, <code class="computeroutput">/etc/config.tcl</code> and
<code class="computeroutput">/etc/daemontools/run</code> and modify
appropriately. Also, copy over several translation-server-only
files:</p><pre class="programlisting">
...TBD
          
</pre>
</li><li class="listitem"><p>Shut down the production site and put up a notice (no procedure
on how to do this yet.)</p></li><li class="listitem"><p>Start the new site, and upgrade it.</p></li><li class="listitem"><p>Go to <a class="ulink" href="/acs-lang/admin" target="_top">ACS
Lang admin page</a> and click "Import All Messages"</p></li><li class="listitem"><p>Resolve conflicts, if any, on the provided page.</p></li><li class="listitem"><p>Back on the admin page, click the export link. If there are
conflicts, the messages will be exported anyway and any errors will
be shown in the web interface.</p></li><li class="listitem"><p>Commit the message catalogs to cvs.</p></li><li class="listitem"><p>From the packages dir, run the acs-lang/bin/check-catalog.sh
script. (This checks for keys no longer in use and some other
things. Until it is rolled into the UI, do it manually and check
the results and take whatever steps you can intuit you should
do.)</p></li><li class="listitem"><p>CVS commit the catalog files. Done</p></li><li class="listitem"><p>If everything went well, reconfigure the new site to take over
the role of the old site (<code class="computeroutput">/etc/config.tcl</code> and <code class="computeroutput">/etc/daemontools/run</code>). Otherwise, bring the
old site back up while investigating problems, and then repeat.</p></li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="releasing-package" leftLabel="Prev" leftTitle="How to package and release an OpenACS
Package"
		    rightLink="ix01" rightLabel="Next" rightTitle="Index"
		    homeLink="index" homeLabel="Home" 
		    upLink="releasing-openacs" upLabel="Up"> 
		