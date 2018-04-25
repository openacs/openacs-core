
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Variables}</property>
<property name="doc(title)">Variables</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="eng-standards-plsql" leftLabel="Prev"
			title="Chapter 12. Engineering
Standards"
			rightLink="automated-testing-best-practices" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="variables" id="variables"></a>Variables</h2></div></div></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="variables-datetime" id="variables-datetime"></a>Date and Time Variables</h3></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red"><span class="cvstag">($&zwnj;Id:
variables.xml,v 1.3 2006/07/17 05:38:37 torbenb Exp
$)</span></span></p><p>By <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">joel\@aufrecht.org</a>
</p>
&lt;/authorblurb&gt;
<p>Starting with OpenACS 5.0 and the introduction of acs-lang, we
recommend retrieving date/time information from the database in
ANSI format and then using <a class="ulink" href="/api-doc/proc-view?proc=lc%5ftime%5ffmt" target="_top">lc_time_fmt</a> to format it for display.</p><div class="example">
<a name="idp140682193355096" id="idp140682193355096"></a><p class="title"><strong>Example 12.1. Getting datetime
from the database ANSI-style</strong></p><div class="example-contents"><pre class="programlisting">db_multirow -extend { mydate_pretty } {
    select to_char(mydate, 'YYYY-MM-DD HH24:MI:SS') as mydate_ansi,
          ...
    ...
} {
    set mydate_ansi [lc_time_system_to_conn $mydate_ansi]
    set mydate_pretty [lc_time_fmt $mydate_ansi "%x %X"]
}
</pre></div>
</div><br class="example-break">
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="eng-standards-plsql" leftLabel="Prev" leftTitle="PL/SQL Standards"
			rightLink="automated-testing-best-practices" rightLabel="Next" rightTitle="Automated Testing"
			homeLink="index" homeLabel="Home" 
			upLink="eng-standards" upLabel="Up"> 
		    