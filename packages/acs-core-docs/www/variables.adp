
<property name="context">{/doc/acs-core-docs {Documentation}} {Variables}</property>
<property name="doc(title)">Variables</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="eng-standards-plsql" leftLabel="Prev"
		    title="
Chapter 12. Engineering Standards"
		    rightLink="automated-testing-best-practices" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="variables" id="variables"></a>Variables</h2></div></div></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="variables-datetime" id="variables-datetime"></a>Date and Time Variables</h3></div></div></div><div class="authorblurb">
<div class="cvstag">($Id: variables.html,v 1.30.2.1 2015/09/23
11:55:06 gustafn Exp $)</div><p>By <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">joel\@aufrecht.org</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>Starting with OpenACS 5.0 and the introduction of acs-lang, we
recommend retrieving date/time information from the database in
ANSI format and then using <a class="ulink" href="/api-doc/proc-view?proc=lc%5ftime%5ffmt" target="_top">lc_time_fmt</a> to format it for display.</p><div class="example">
<a name="idp140480085039184" id="idp140480085039184"></a><p class="title"><b>Example 12.1. Getting
datetime from the database ANSI-style</b></p><div class="example-contents"><pre class="programlisting">
db_multirow -extend { mydate_pretty } {
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
		