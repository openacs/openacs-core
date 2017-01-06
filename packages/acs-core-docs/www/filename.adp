
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Detailed Design Documentation Template}</property>
<property name="doc(title)">Detailed Design Documentation Template</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="nxml-mode" leftLabel="Prev"
		    title="
Chapter 13. Documentation Standards"
		    rightLink="requirements-template" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="filename" id="filename"></a>Detailed Design Documentation Template</h2></div></div></div><p>By <a class="ulink" href="mailto:youremail\@example.com" target="_top">You</a>
</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-start-note" id="yourpackage-design-start-note"></a>Start Note</h3></div></div></div><p><span class="emphasis"><em>NOTE: Some of the sections of this
template may not apply to your package, e.g. there may be no
user-visible UI elements for a component of the OpenACS Core.
Furthermore, it may be easier in some circumstances to join certain
sections together, e.g. it may make sense to discuss the data model
and transactions API together instead of putting them in separate
sections. And on occasion, you may find it easier to structure the
design discussion by the structure used in the requirements
document. As this template is just a starting point, use your own
judgment, consult with peers when possible, and adapt
intelligently.</em></span></p><p><span class="emphasis"><em>Also, bear in mind <span class="strong"><strong>the audience</strong></span> for detailed design:
fellow programmers who want to maintain/extend the software, AND
parties interested in evaluating software quality.</em></span></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-essentials" id="yourpackage-design-essentials"></a>Essentials</h3></div></div></div><p>When applicable, each of the following items should receive its
own link:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>User directory</p></li><li class="listitem"><p>OpenACS administrator directory</p></li><li class="listitem"><p>Subsite administrator directory</p></li><li class="listitem"><p>Tcl script directory (link to the API browser page for the
package)</p></li><li class="listitem"><p>PL/SQL file (link to the API browser page for the package)</p></li><li class="listitem"><p>Data model</p></li><li class="listitem"><p>Requirements document</p></li><li class="listitem"><p>ER diagram</p></li><li class="listitem"><p>Transaction flow diagram</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-introduction" id="yourpackage-design-introduction"></a>Introduction</h3></div></div></div><p>This section should provide an overview of the package and
address at least the following issues:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>What this package is intended to allow the user (or different
classes of users) to accomplish.</p></li><li class="listitem"><p>Within reasonable bounds, what this package is not intended to
allow users to accomplish.</p></li><li class="listitem"><p>The application domains where this package is most likely to be
of use.</p></li><li class="listitem"><p>A high-level overview of how the package meets its requirements
(which should have been documented elsewhere). This is to include
relevant material from the "features" section of the
cover sheet (the cover sheet is a wrapper doc with links to all
other package docs).</p></li>
</ul></div><p>Also worthy of treatment in this section:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p>When applicable, a careful demarcation between the functionality
of this package and others which - at least superficially - appear
to address the same requirements.</p></li></ul></div><p>Note: it&#39;s entirely possible that a discussion of what a
package is not intended to do differs from a discussion of future
improvements for the package.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-historical-consid" id="yourpackage-design-historical-consid"></a>Historical
Considerations</h3></div></div></div><p>For a given set of requirements, typically many possible
implementations and solutions exist. Although eventually only one
solution is implemented, a discussion of the alternative solutions
canvassed - noting why they were rejected - proves helpful to both
current and future developers. All readers would be reminded as to
why and how the particular solution developed over time, avoiding
re-analysis of problems already solved.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-competitive-analysis" id="yourpackage-design-competitive-analysis"></a>Competitive
Analysis</h3></div></div></div><p>Although currently only a few package documentation pages
contain a discussion of competing software, (e.g. chat, portals),
this section should be present whenever such competition
exists.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>If your package exhibits features missing from competing
software, this fact should be underscored.</p></li><li class="listitem"><p>If your package lacks features which are present in competing
software, the reasons for this should be discussed here; our sales
team needs to be ready for inquiries regarding features our
software lacks.</p></li>
</ul></div><p>Note that such a discussion may differ from a discussion of a
package&#39;s potential future improvements.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-design-tradeoffs" id="yourpackage-design-design-tradeoffs"></a>Design Tradeoffs</h3></div></div></div><p>No single design solution can optimize every desirable software
attribute. For example, an increase in the security of a system
will likely entail a decrease in its ease-of-use, and an increase
in the flexibility/generality of a system typically entails a
decrease in the simplicity and efficiency of that system. Thus a
developer must decide to put a higher value on some attributes over
others: this section should include a discussion of the tradeoffs
involved with the design chosen, and the reasons for your choices.
Some areas of importance to keep in mind are:</p><p>Areas of interest to users:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Performance: availability and efficiency</p></li><li class="listitem"><p>Flexibility</p></li><li class="listitem"><p>Interoperability</p></li><li class="listitem"><p>Reliability and robustness</p></li><li class="listitem"><p>Usability</p></li>
</ul></div><p>Areas of interest to developers:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Maintainability</p></li><li class="listitem"><p>Portability</p></li><li class="listitem"><p>Reusability</p></li><li class="listitem"><p>Testability</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-api" id="yourpackage-design-api"></a>API</h3></div></div></div><p>Here&#39;s where you discuss the abstractions used by your
package, such as the procedures encapsulating the legal
transactions on the data model. Explain the organization of
procedures and their particulars (detail above and beyond what is
documented in the code), including:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Problem-domain components: key algorithms, e.g. a specialized
statistics package would implement specific mathematical
procedures.</p></li><li class="listitem"><p>User-interface components: e.g. HTML widgets that the package
may need.</p></li><li class="listitem"><p>Data management components: procedures that provide a stable
interface to database objects and legal transactions - the latter
often correspond to tasks.</p></li>
</ul></div><p>Remember that the correctness, completeness, and stability of
the API and interface are what experienced members of our audience
are looking for. This is a cultural shift for us at aD (as of
mid-year 2000), in that we&#39;ve previously always looked at the
data models as key, and seldom spent much effort on the API (e.g.
putting raw SQL in pages to handle transactions, instead of
encapsulating them via procedures). Experience has taught us that
we need to focus on the API for maintainability of our systems in
the face of constant change.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-data-model" id="yourpackage-design-data-model"></a>Data Model Discussion</h3></div></div></div><p>The data model discussion should do more than merely display the
SQL code, since this information is already be available via a link
in the "essentials" section above. Instead, there should
be a high-level discussion of how your data model meets your
solution requirements: why the database entities were defined as
they are, and what transactions you expect to occur. (There may be
some overlap with the API section.) Here are some starting
points:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The data model discussion should address the intended usage of
each entity (table, trigger, view, procedure, etc.) when this
information is not obvious from an inspection of the data model
itself.</p></li><li class="listitem"><p>If a core service or other subsystem is being used (e.g., the
new parties and groups, permissions, etc.) this should also be
mentioned.</p></li><li class="listitem"><p>Any default permissions should be identified herein.</p></li><li class="listitem"><p>Discuss any data model extensions which tie into other
packages.</p></li><li class="listitem">
<p><span class="strong"><strong>Transactions</strong></span></p><p>Discuss modifications which the database may undergo from your
package. Consider grouping legal transactions according to the
invoking user class, i.e. transactions by an OpenACS-admin, by
subsite-admin, by a user, by a developer, etc.</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-ui" id="yourpackage-design-ui"></a>User Interface</h3></div></div></div><p>In this section, discuss user interface issues and pages to be
built; you can organize by the expected classes of users. These may
include:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Developers</p></li><li class="listitem"><p>OpenACS administrators (previously known as site-wide
administrators)</p></li><li class="listitem"><p>Subsite administrators</p></li><li class="listitem"><p>End users</p></li>
</ul></div><p>You may want to include page mockups, site-maps, or other visual
aids. Ideally this section is informed by some prototyping
you&#39;ve done, to establish the package&#39;s usability with the
client and other interested parties.</p><p><span class="emphasis"><em>Note: In order that developer
documentation be uniform across different system documents, these
users should herein be designated as "the developer,"
"the OpenACS-admin," "the sub-admin," and
"the user," respectively.</em></span></p><p>Finally, note that as our templating system becomes more
entrenched within the OpenACS, this section&#39;s details are
likely to shift from UI specifics to template interface
specifics.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-config" id="yourpackage-design-config"></a>Configuration/Parameters</h3></div></div></div><p>Under OpenACS 5.9.0, parameters are set at two levels: at the
global level by the OpenACS-admin, and at the subsite level by a
sub-admin. In this section, list and discuss both levels of
parameters.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-future" id="yourpackage-design-future"></a>Future Improvements/Areas of Likely
Change</h3></div></div></div><p>If the system presently lacks useful/desirable features, note
details here. You could also comment on non-functional improvements
to the package, such as usability.</p><p>Note that a careful treatment of the earlier "competitive
analysis" section can greatly facilitate the documenting of
this section.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-authors" id="yourpackage-design-authors"></a>Authors</h3></div></div></div><p>Although a system&#39;s data model file often contains this
information, this isn&#39;t always the case. Furthermore, data
model files often undergo substantial revision, making it difficult
to track down the system creator. An additional complication:
package documentation may be authored by people not directly
involved in coding. Thus to avoid unnecessary confusion, include
email links to the following roles as they may apply:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>System creator</p></li><li class="listitem"><p>System owner</p></li><li class="listitem"><p>Documentation author</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="yourpackage-design-revision-history" id="yourpackage-design-revision-history"></a>Revision History</h3></div></div></div><p><span class="emphasis"><em>The revision history table below is
for this template - modify it as needed for your actual design
document.</em></span></p><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><thead><tr>
<th>Document Revision #</th><th>Action Taken, Notes</th><th>When?</th><th>By Whom?</th>
</tr></thead><tbody>
<tr>
<td>0.3</td><td>Edited further, incorporated feedback from Michael Yoon</td><td>9/05/2000</td><td>Kai Wu</td>
</tr><tr>
<td>0.2</td><td>Edited</td><td>8/22/2000</td><td>Kai Wu</td>
</tr><tr>
<td>0.1</td><td>Creation</td><td>8/21/2000</td><td>Josh Finkler, Audrey McLoghlin</td>
</tr>
</tbody>
</table></div><div class="cvstag">($&zwnj;Id: design-template.xml,v 1.8.14.1 2016/06/23
08:32:46 gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="nxml-mode" leftLabel="Prev" leftTitle="Using nXML mode in Emacs"
		    rightLink="requirements-template" rightLabel="Next" rightTitle="System/Application Requirements
Template"
		    homeLink="index" homeLabel="Home" 
		    upLink="doc-standards" upLabel="Up"> 
		