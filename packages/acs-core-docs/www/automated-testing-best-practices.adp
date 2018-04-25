
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Automated Testing}</property>
<property name="doc(title)">Automated Testing</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="variables" leftLabel="Prev"
			title="Chapter 12. Engineering
Standards"
			rightLink="doc-standards" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="automated-testing-best-practices" id="automated-testing-best-practices"></a>Automated Testing</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By <a class="ulink" href="mailto:davis\@xarg.net" target="_top">Jeff Davis</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><p>Best practices in writing OpenACS automated tests</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<strong>Special characters in Tcl. </strong> Try strings
starting with a <code class="computeroutput">-Bad</code> and
strings containing <code class="computeroutput">[BAD]</code>,
<code class="computeroutput">{</code>, <code class="computeroutput">\077</code>, and <code class="computeroutput">$Bad</code>. For user input, <code class="computeroutput">[BAD]</code> should never be evaluated,
<code class="computeroutput">\077</code> should not be turned into
a <code class="computeroutput">?</code> and <code class="computeroutput">$Bad</code> should not be interpolated. The string
<code class="computeroutput">-Bad [BAD] \077 { $Bad</code> should
be valid user input, should pass through the system unaltered, and
if it isn&#39;t that&#39;s a bug.</p></li><li class="listitem"><p>
<strong>Quoting issues. </strong> Put some html in plain
text fields and make sure the result is properly quoted anywhere it
shows up (I use "&lt;b&gt;bold&lt;/b&gt;" usually). Look
out especially for quoting errors in the context bar and in round
trips via an edit form. For fields that disallow html tags you can
use <code class="computeroutput">&amp;amp;</code> to check that the
field is quoted properly. If it is not displayed as <code class="computeroutput">&amp;amp;</code> then the quoting for the field is
incorrect. (It&#39;s not clear whether this should be considered an
error but given that data for text fields can come from various
sources if it&#39;s text it should be properly quoted and we should
not rely on input validation to prevent XSS security holes.)</p></li><li class="listitem"><p>
<strong>Whitespace input. </strong> Check that whitespace
is not considered valid input for a field if it does not make
sense. For example, the subject of a forum post is used to
construct a link and if it is " " it will have a link of
<code class="computeroutput">&lt;a href="..."&gt;
&lt;/a&gt;</code> which would not be clickable if whitespace was
allowed as a valid input.</p></li><li class="listitem"><p>
<strong>Doubleclick. </strong> Make sure that if you submit
a form, use the back button, and submit again that the behavior is
reasonable (correct behavior depends on what the form is for, but a
server error is not reasonable).</p></li><li class="listitem"><p>
<strong>Duplicate names. </strong> Make sure that if a
duplicate name is entered that there is a reasonable error rather
than a server error. Check for insert, move, copy, and rename.</p></li>
</ul></div><p><span class="cvstag">($&zwnj;Id: auto-testing.xml,v 1.4 2017/08/07
23:47:54 gustafn Exp $)</span></p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="variables" leftLabel="Prev" leftTitle="Variables"
			rightLink="doc-standards" rightLabel="Next" rightTitle="Chapter 13. Documentation
Standards"
			homeLink="index" homeLabel="Home" 
			upLink="eng-standards" upLabel="Up"> 
		    