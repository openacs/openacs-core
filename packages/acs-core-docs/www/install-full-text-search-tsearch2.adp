
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install Full Text Search using Tsearch2}</property>
<property name="doc(title)">Install Full Text Search using Tsearch2</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install-nspam" leftLabel="Prev"
			title="Appendix B. Install
additional supporting software"
			rightLink="install-nsopenssl" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-full-text-search-tsearch2" id="install-full-text-search-tsearch2"></a>Install Full Text Search
using Tsearch2</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By <a class="ulink" href="mailto:dave\@thedesignexperience.org" target="_top">Dave Bauer</a>,
<a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel
Aufrecht</a> and <a class="ulink" href="mailto:openacs\@sussdorff.de" target="_top">Malte Sussdorff</a>
with help from <a class="ulink" href="http://www.sai.msu.su/~megera/postgres/gist/tsearch/V2/docs/tsearch-V2-intro.html" target="_top">Tsearch V2 Introduction by Andrew J.
Kopciuch</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-tsearch2" id="install-tsearch2"></a>Install Tsearch2 module</h3></div></div></div><a class="indexterm" name="idp140682186280760" id="idp140682186280760"></a><p>In earlier versions of PostgreSQL (7.4), tsearch2 was a contrib
module. With PostgreSQL 9.*, it was included in the standard
PostgreSQL package with minor naming changes (e.g. the function
"rank" became "ts_rank"). PostgreSQL 9 included
a backward compatibility module named "tsearch2". Newer
OpenACS installations (at least 5.9.0 or newer) do not need the
compatibility package. In PostgreSQL 10 the tsearch2 compatibility
package has been removed.</p><p>On new OpenACS installations for PostgreSQL, install the
tsearch2-driver package via "/acs-admin/install/" and
mount the search package under "/search" via
"/admin/site-map" if necessary.</p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install-nspam" leftLabel="Prev" leftTitle="Install nspam"
			rightLink="install-nsopenssl" rightLabel="Next" rightTitle="Install nsopenssl"
			homeLink="index" homeLabel="Home" 
			upLink="install-more-software" upLabel="Up"> 
		    