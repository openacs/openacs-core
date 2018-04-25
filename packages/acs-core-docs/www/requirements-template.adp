
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {System/Application Requirements Template}</property>
<property name="doc(title)">System/Application Requirements Template</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="filename" leftLabel="Prev"
			title="Chapter 13. Documentation
Standards"
			rightLink="i18n" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="requirements-template" id="requirements-template"></a>System/Application Requirements
Template</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By <a class="ulink" href="mailto:youremail\@example.com" target="_top">You</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-requirements-introduction" id="yourpackage-requirements-introduction"></a>Introduction</h3></div></div></div><p><span class="emphasis"><em>Briefly explain to the reader what
this document is for, whether it records the requirements for a new
system, a client application, a toolkit subsystem, etc. Remember
your audience: fellow programmers, AND interested non-technical
parties such as potential clients, who may all want to see how
rigorous our engineering process is. Here and everywhere, write
clearly and precisely; for requirements documentation, write at a
level that any intelligent layperson can
understand.</em></span></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-requirements-vision" id="yourpackage-requirements-vision"></a>Vision Statement</h3></div></div></div><p><span class="emphasis"><em>Very broadly, describe how the system
meets a need of a business, group, the OpenACS as a whole, etc.
Make sure that technical and non-technical readers alike would
understand what the system would do and why it&#39;s useful.
Whenever applicable, you should explicitly state what the business
value of the system is.</em></span></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-requirements-system-app-overview" id="yourpackage-requirements-system-app-overview"></a>System/Application
Overview</h3></div></div></div><p><span class="emphasis"><em>Discuss the high-level breakdown of
the components that make up the system. You can go by functional
areas, by the main transactions the system allows,
etc.</em></span></p><p><span class="emphasis"><em>You should also state the context and
dependencies of the system here, e.g. if it&#39;s an
application-level package for OpenACS 4, briefly describe how it
uses kernel services, like permissions or subsites.</em></span></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-requirements-cases" id="yourpackage-requirements-cases"></a>Use-cases and
User-scenarios</h3></div></div></div><p><span class="emphasis"><em>Determine the types or classes of
users who would use the system, and what their experience would be
like at a high-level. Sketch what their experience would be like
and what actions they would take, and how the system would support
them.</em></span></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-requirements-competitive-analysis" id="yourpackage-requirements-competitive-analysis"></a>Optional:
Competitive Analysis</h3></div></div></div><p><span class="emphasis"><em>Describe other systems or services
that are comparable to what you&#39;re building. If applicable, say
why your implementation will be superior, where it will match the
competition, and where/why it will lack existing best-of-breed
capabilities. This section is also in the Design doc, so write
about it where you deem most appropriate.</em></span></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-requirements-links" id="yourpackage-requirements-links"></a>Related Links</h3></div></div></div><p>Include all pertinent links to supporting and related material,
such as:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>System/Package "coversheet" - where all documentation
for this software is linked off of</p></li><li class="listitem"><p>Design document</p></li><li class="listitem"><p>Developer&#39;s guide</p></li><li class="listitem"><p>User&#39;s guide</p></li><li class="listitem"><p>Other-cool-system-related-to-this-one document</p></li><li class="listitem"><p>Test plan</p></li><li class="listitem"><p>Competitive system(s)</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-requirements-requirements" id="yourpackage-requirements-requirements"></a>Requirements</h3></div></div></div><p><span class="emphasis"><em>The main course of the document,
requirements. Break up the requirements sections (A, B, C, etc.) as
needed. Within each section, create a list denominated with unique
identifiers that reflect any functional hierarchy present, e.g.
20.5.13. - for the first number, leave generous gaps on the first
writing of requirements (e.g. 1, 10, 20, 30, 40, etc.) because
you&#39;ll want to leave room for any missing key requirements that
may arise.</em></span></p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<p><span class="strong"><strong>10.0 A Common
Solution</strong></span></p><p>Programmers and designers should only have to learn a single
system that serves as a UI substrate for all the functionally
specific modules in the toolkit.</p><div class="blockquote"><blockquote class="blockquote">
<p><span class="strong"><strong>10.0.1</strong></span></p><p>The system should not make any assumptions about how pages
should look or function.</p><p><span class="strong"><strong>10.0.5</strong></span></p><p>Publishers should be able to change the default presentation of
any module using a single methodology with minimal exposure to
code.</p>
</blockquote></div>
</li></ul></div><p>For guidelines writing requirements, take a look at <a class="ulink" href="http://www.utm.mx/~caff/doc/OpenUPWeb/openup/guidances/guidelines/writing_good_requirements_48248536.html" target="_top">quality standards</a> or <a class="ulink" href="https://ep.jhu.edu/about-us/news-and-media/writing-good-requirements-checklists" target="_top">requirements checklist</a>, along with a good
example, such as <a class="xref" href="apm-requirements" title="Package Manager Requirements">Package Manager
Requirements</a>.</p><p>Besides writing requirements in natural language, consider using
the following techniques as needed:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Pseudocode - a quasi programming language, combining the
informality of natural language with the strict syntax and control
structures of a programming language.</p></li><li class="listitem"><p>Finite State Machines - a hypothetical machine that can be in
only one of a given number of states at any specific time. Useful
to model situations that are rigidly deterministic, that is, any
set of inputs mathematically determines the system outputs.</p></li><li class="listitem"><p>Decision Trees and Decision Tables - similar to FSMs, but better
suited to handle combinations of inputs.</p></li><li class="listitem"><p>Flowcharts - easy to draw and understand, suited for event and
decision driven systems. UML is the industry standard here.</p></li><li class="listitem"><p>Entity-Relationship diagrams - a necessary part of Design
documents, sometimes a high-level ER diagram is useful for
requirements as well.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-requirements-implementation" id="yourpackage-requirements-implementation"></a>Optional:
Implementation Notes</h3></div></div></div><p><span class="emphasis"><em>Although in theory coding comes after
design, which comes after requirements, we do not, and perhaps
should not, always follow such a rigid process (a.k.a. the
waterfall lifecyle). Often, there is a pre-existing system or
prototype first, and thus you may want to write some thoughts on
implementation, for aiding and guiding yourself or other
programmers.</em></span></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-revision-history" id="yourpackage-revision-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><thead><tr>
<th class="revisionheader">Document Revision #</th><th>Action Taken, Notes</th><th>When?</th><th>By Whom?</th>
</tr></thead><tbody>
<tr>
<td class="revisionbody">0.3</td><td>Edited further, incorporated feedback from Michael Yoon</td><td>9/05/2000</td><td>Kai Wu</td>
</tr><tr>
<td>0.2</td><td>Edited</td><td>8/22/2000</td><td>Kai Wu</td>
</tr><tr>
<td>0.1</td><td>Created</td><td>8/21/2000</td><td>Josh Finkler, Audrey McLoghlin</td>
</tr>
</tbody>
</table></div><p><span class="cvstag">($&zwnj;Id: requirements-template.xml,v 1.7
2017/08/07 23:47:54 gustafn Exp $)</span></p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="filename" leftLabel="Prev" leftTitle="Detailed Design Documentation
Template"
			rightLink="i18n" rightLabel="Next" rightTitle="
Chapter 14. Internationalization"
			homeLink="index" homeLabel="Home" 
			upLink="doc-standards" upLabel="Up"> 
		    