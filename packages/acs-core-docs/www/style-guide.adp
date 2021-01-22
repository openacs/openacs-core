
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {OpenACS Style Guide}</property>
<property name="doc(title)">OpenACS Style Guide</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="eng-standards" leftLabel="Prev"
		    title="
Chapter 12. Engineering Standards"
		    rightLink="cvs-guidelines" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="style-guide" id="style-guide"></a>OpenACS Style Guide</h2></div></div></div><p>By Jeff Davis</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="style-guide-motivation" id="style-guide-motivation"></a>Motivation</h3></div></div></div><p>Why have coding standards for OpenACS? And if the code works why
change it to adhere to some arbitrary rules?</p><p>Well, first lets consider the OpenACS code base (all this as of
December 2003 and including dotLRN). There are about 390,000 lines
of Tcl code, about 460,000 lines of sql (in datamodel scripts and
.xql files), about 80,000 lines of markup in .adp files, and about
100,000 lines of documentation. All told, just about a million
lines of "stuff". In terms of logical units there are
about 160 packages, 800 tables, 2,000 stored procedures, about
2,000 functional pages, and about 3,200 Tcl procedures.</p><p>When confronted by this much complexity it&#39;s important to be
able to make sense of it without having to wade through it all.
Things should be coherent, things should be named predictably and
behave like you would expect, and your guess about what something
is called or where it is should be right more often than not
because the code follows the rules.</p><p>Unfortunately, like any large software project written over a
long period by a lot of different people, OpenACS sometimes lacks
this basic guessability and in the interest of bringing it into
line we have advanced these guidelines.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="style-commandments" id="style-commandments"></a>Commandments</h3></div></div></div><p>Here is a short list of the basic rules code contributed to
OpenACS should follow...</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<strong>Follow the file naming and the package structure
rules. </strong> Some of the file naming rules are
requirements for things to function correctly (for example data
model creation scripts and Tcl library files must be named properly
to be used), while some are suggestions (the <span class="emphasis"><em>object-verb</em></span> naming convention) which if
ignored won&#39;t break anything, but if you follow the rules
people will be able to understand your package much more
easily.</p></li><li class="listitem"><p>
<strong>Be literate in your programming. </strong>
Use ad_proc, ad_library, and ad_page_contract to provide
documentation for your code, use comments on your datamodel,
explain what things mean and how they should work.</p></li><li class="listitem"><p>
<strong>Test. </strong> Write test cases for your
API and data model; test negative cases as well as positive;
document your tests. Provide tests for bugs which are not yet
fixed. Test, Test, Test.</p></li><li class="listitem"><p>
<strong>Use namespaces. </strong> For new packages
choose a namespace and place all procedures in it and in oracle
create packages.</p></li><li class="listitem"><p>
<strong>Follow the constraint naming and the PL/SQL and PL/pgSQL
rules. </strong> Naming constraints is important for
upgradability and for consistency. Also, named constraints can be
immensely helpful in developing good error handling. Following the
PL/SQL and PL/pgSQL rules ensure that the procedures created can be
handled similarly across both Oracle and PostgreSQL databases.</p></li><li class="listitem"><p>
<strong>Follow the code formatting
guidelines. </strong> The code base is very large and
if things are formatted consistently it is easier to read. Also, if
it conforms to the standard it won&#39;t be reformatted (which can
mask the change history and making tracking down bugs much harder).
Using spaces rather than tabs makes patches easier to read and
manage and does not force other programmers to decipher what tab
settings you had in place in your editor.</p></li><li class="listitem"><p>
<strong>Use the standard APIs. </strong> Don&#39;t
reinvent the wheel. Prefer extending an existing core API to
creating your own. If something in the core does not meet your
particular needs it probably won&#39;t meet others as well and
fleshing out the core API&#39;s makes the toolkit more useful for
everyone and more easily extended.</p></li><li class="listitem"><p>
<strong>Make sure your datamodel create/drop scripts
work. </strong> Break the table creation out from the
package/stored procedure creation and use <code class="computeroutput">create or replace</code> where possible so that
scripts can be sourced more than once. Make sure your drop script
works if data has been inserted (and permissioned and notifications
have been attached etc).</p></li><li class="listitem">
<p>
<strong>Practice CVS/Bug Tracker Hygiene. </strong>
Commit your work. commit with sensible messages and include patch
and bug numbers in your commit messages.</p><p>Create bug tracker tickets for things you are going to work on
yourself (just in case you don&#39;t get to it and to act as a
pointer for others who might encounter the same problem).</p>
</li><li class="listitem"><p>
<strong>Solicit code reviews. </strong> Ask others
to look over your code and provide feedback and do the same for
others.</p></li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="style-guide-rev-history" id="style-guide-rev-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><thead><tr>
<th>Document Revision #</th><th>Action Taken, Notes</th><th>When?</th><th>By Whom?</th>
</tr></thead><tbody><tr>
<td>0.1</td><td>Creation</td><td>12/2003</td><td>Jeff Davis</td>
</tr></tbody>
</table></div><div class="cvstag">($&zwnj;Id: style-guide.xml,v 1.3.14.3 2017/04/22
17:18:48 gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="eng-standards" leftLabel="Prev" leftTitle="
Chapter 12. Engineering Standards"
		    rightLink="cvs-guidelines" rightLabel="Next" rightTitle="CVS Guidelines"
		    homeLink="index" homeLabel="Home" 
		    upLink="eng-standards" upLabel="Up"> 
		