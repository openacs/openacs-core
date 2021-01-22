
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Groups Requirements}</property>
<property name="doc(title)">Groups Requirements</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="permissions-design" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="groups-design" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="groups-requirements" id="groups-requirements"></a>Groups Requirements</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="http://planitia.org" target="_top">Rafael H. Schloming</a>, Mark Thomas</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-requirements-intro" id="groups-requirements-intro"></a>Introduction</h3></div></div></div><p>Almost all database-backed websites have users, and need to
model the grouping of users. The OpenACS 4 Parties and Groups
system is intended to provide the flexibility needed to model
complex real-world organizational structures, particularly to
support powerful subsite services; that is, where one OpenACS
installation can support what appears to the user as distinct web
services for different user communities.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-requirements-vision" id="groups-requirements-vision"></a>Vision Statement</h3></div></div></div><p>A powerful web service that can meet the needs of large
enterprises must be able to model the the real world&#39;s very
rich organizational structures and many ways of decomposing the
same organization. For example, a corporation can be broken into
structures (the corporation, its divisions, and their departments)
or regions (the Boston office, the LA office); a person who is
employed by (is a member of) a specific department is also a member
of the division and the corporation, and works at (is a member of,
but in a different sense) a particular office. OpenACS&#39;s
Parties and Groups system will support such complex relations
faithfully.</p><p><span class="strong"><strong>Historical
Motivations</strong></span></p><p>The primary limitation of the OpenACS 3.x user group system is
that it restricts the application developer to representing a
"flat group" that contains only users: The <code class="computeroutput">user_groups</code> table may contain the
<code class="computeroutput">group_id</code> of a parent group, but
parent-child relationship support is limited because it only allows
one kind of relationship between groups to be represented.
Moreover, the Oracle database&#39;s limited support for tree-like
structures makes the queries over these relationships
expensive.</p><p>In addition, the Module Scoping design in OpenACS 3.0 introduced
a <span class="emphasis"><em>party</em></span> abstraction - a
thing that is a person or a group of people - though not in the
form of an explicit table. Rather, the triple of <code class="computeroutput">scope</code>, <code class="computeroutput">user_id</code>, and <code class="computeroutput">group_id</code> columns was used to identify the
party. One disadvantage of this design convention is that it
increases a data model&#39;s complexity by requiring the programmer
to:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>add these three columns to each "scoped" table</p></li><li class="listitem"><p>define a multi-column check constraint to protect against data
corruption (e.g., a row with a <code class="computeroutput">scope</code> value of "group" but a null
<code class="computeroutput">group_id</code>)</p></li><li class="listitem"><p>perform extra checks in <code class="computeroutput">Tcl</code>
and <code class="computeroutput">PL/SQL</code> functions and
procedures to check both the <code class="computeroutput">user_id</code> and <code class="computeroutput">group_id</code> values</p></li>
</ul></div><p>In sum, the goal of the <span class="strong"><strong>Parties and
Groups</strong></span> system is to provide OpenACS programmers and
site administrators with simple tools that fully describe the
complex relationships that exist among groups in the real
world.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-requirements-user-scenarios" id="groups-requirements-user-scenarios"></a>User Scenarios</h3></div></div></div><p>Pat Developer has a client project and wants to model the
company, its offices, its divisions, and its departments as groups
and the employees as users.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-requirements-system-overview" id="groups-requirements-system-overview"></a>System Overview</h3></div></div></div><p>We start with <span class="strong"><strong>Groups</strong></span>, which contain members; the
<span class="strong"><strong>member can be either a person or
another group</strong></span> (i.e. a member is a party).</p><p>In addition to membership, the party and groups system defines a
<span class="strong"><strong>composition</strong></span>
relationship that may exist between groups: A group can be a
<span class="strong"><strong>component</strong></span> of another
group. The child group is called a <span class="emphasis"><em>component group</em></span>; the parent group is
called a <span class="emphasis"><em>composite
group</em></span>.</p><p>A group <span class="strong"><strong>G<sub>c</sub>
</strong></span> can be a member
and/or a component of another group <span class="strong"><strong>G<sub>p</sub>
</strong></span>; the difference is
in the way the members of <span class="strong"><strong>G<sub>c</sub>
</strong></span> are related to
<span class="strong"><strong>G<sub>p</sub>
</strong></span>:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>If a party <span class="strong"><strong>P</strong></span> is a
member (or a component) of <span class="strong"><strong>G<sub>c</sub>
</strong></span> and if <span class="strong"><strong>G<sub>c</sub>
</strong></span> is a component of
<span class="strong"><strong>G<sub>p</sub>
</strong></span>, then
<span class="strong"><strong>P</strong></span> is also a member (or
a component) of <span class="strong"><strong>G<sub>p</sub>
</strong></span>
</p></li><li class="listitem"><p>If a party <span class="strong"><strong>P</strong></span> is a
member (or a component) of <span class="strong"><strong>G<sub>c</sub>
</strong></span> and if <span class="strong"><strong>G<sub>c</sub>
</strong></span> is a member of
<span class="strong"><strong>G<sub>p</sub>
</strong></span>, then
<span class="strong"><strong>no relationship</strong></span>
between <span class="strong"><strong>P</strong></span> and
<span class="strong"><strong>G<sub>p</sub>
</strong></span> exists
as a result of the relationship between <span class="strong"><strong>G<sub>p</sub>
</strong></span> and <span class="strong"><strong>G<sub>p</sub>
</strong></span>.</p></li>
</ul></div><p>Consider an example to make this less abstract: Pretend that the
Sierra Club is a <span class="emphasis"><em>member</em></span> of
Greenpeace. The Sierra Club has chapters; each chapter is a
<span class="emphasis"><em>component</em></span> of the Sierra
Club. If Eddie Environmentalist is a member of the Massachusetts
Chapter of the Sierra Club, Eddie is automatically a member of the
Sierra Club, but being a Sierra Club member does not make Eddie a
member of Greenpeace.</p><p>In the OpenACS, Greenpeace, Sierra Club, and the Sierra Club
chapters would be modeled as groups, and Eddie would be a user.
There would be a composition relationship between each Sierra Club
chapter and the Sierra Club. Membership relationships would exist
between Eddie and the Massachusetts Chapter, between Eddie and the
Sierra Club (due to Eddie&#39;s membership in the Massachusetts
chapter), and between the Sierra Club and Greenpeace.</p><p>Membership requirements can vary from group to group. The
parties and groups system must provide a base type that specifies
the bare minimum necessary to join a group.</p><p>The parties and groups system must support constraints between a
composite group <span class="strong"><strong>G<sub>P</sub>
</strong></span> and any of its
component groups, <span class="strong"><strong>G<sub>C</sub>
</strong></span>. For example, the
system should be able to enforce a rule like: Do not allow a party
<span class="strong"><strong>P</strong></span> to become a member
of <span class="strong"><strong>G<sub>C</sub>
</strong></span>
unless <span class="strong"><strong>P</strong></span> is already a
member of <span class="strong"><strong>G<sub>P</sub>
</strong></span>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-requirements-links" id="groups-requirements-links"></a>Related Links</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p><a class="xref" href="groups-design" title="Groups Design">OpenACS 4 Groups Design</a></p></li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-requirements-data-model" id="groups-requirements-data-model"></a>Requirements: Data Model</h3></div></div></div><p>The data model for the parties and groups system must provide
support for the following types of entities:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><span class="strong"><strong>10.0
Parties</strong></span></span></dt><dd>
<p>A <span class="strong"><strong>party</strong></span> is an
entity used to represent either a <span class="emphasis"><em>group</em></span> or a <span class="emphasis"><em>person</em></span>.</p><p>The data model should enforce these constraints:</p><p>
<span class="strong"><strong>10.10</strong></span> A party has
an email address, which can be empty.</p><p>
<span class="strong"><strong>10.20</strong></span> A party may
have multiple email addresses associated with it.</p><p>
<span class="strong"><strong>10.30</strong></span> The email
address of a party must be unique within an OpenACS system.</p>
</dd><dt><span class="term"><span class="strong"><strong>20.0
Groups</strong></span></span></dt><dd>
<p>A <span class="strong"><strong>group</strong></span> is a
collection of zero or more parties.</p><p>
<span class="strong"><strong>20.10</strong></span> The data
model should support the subclassing of groups via OpenACS
Objects.</p>
</dd><dt><span class="term"><span class="strong"><strong>30.0
Persons</strong></span></span></dt><dd>
<p>A <span class="strong"><strong>person</strong></span> represents
an actual human being, past or present.</p><p>
<a name="groups-requirements-30-10" id="groups-requirements-30-10"></a><span class="strong"><strong>30.10.</strong></span> A person must have an
associated name.</p>
</dd><dt><span class="term"><span class="strong"><strong>40.0
Users</strong></span></span></dt><dd>
<p>A <span class="strong"><strong>user</strong></span> is a person
who has registered with an OpenACS site. A user may have additional
attributes, such as a screen name.</p><p>The data model should enforce these constraints:</p><p>
<span class="strong"><strong>40.10</strong></span> A user must
have a non-empty email address.</p><p>
<span class="strong"><strong>40.20</strong></span> Two different
users may not have the same email address on a single OpenACS
installation; i.e., an email address identifies a single user on
the system.</p><p>
<span class="strong"><strong>40.30</strong></span> A user may
have multiple email addresses; for example, two or more email
addresses may identify a single user.</p><p>
<span class="strong"><strong>40.40</strong></span> A user must
have password field which can be empty.</p>
</dd>
</dl></div><p>The data model for the parties and groups system must provide
support for the following types of relationships between
entities:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><span class="strong"><strong>50.0
Membership</strong></span></span></dt><dd>
<p>A party <span class="strong"><strong>P</strong></span> is
considered a <span class="strong"><strong>member</strong></span> of
a group <span class="strong"><strong>G</strong></span>
</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>when a direct membership relationship exists between
<span class="strong"><strong>P</strong></span> and <span class="strong"><strong>G</strong></span>
</p></li><li class="listitem"><p>or when there exists a direct membership relationship between
<span class="strong"><strong>P</strong></span> and some group
<span class="strong"><strong>G<sub>C</sub>
</strong></span> and
<span class="strong"><strong>G<sub>C</sub>
</strong></span> has a
composition relationship (c.f., <a class="link" href="groups-requirements">60.0</a>) with
<span class="strong"><strong>G</strong></span>.</p></li>
</ul></div><p>
<span class="strong"><strong>50.10</strong></span> A party may
be a member of multiple groups.</p><p>
<span class="strong"><strong>50.20</strong></span> A party may
be a member of the same group multiple times only when all the
memberships have different types; for example, Jane may be a member
of The Company by being both an Employee and an Executive.</p><p>
<span class="strong"><strong>50.30</strong></span> A party as a
member of itself is not supported.</p><p>
<span class="strong"><strong>50.40</strong></span> The data
model must support membership constraints.</p><p>
<span class="strong"><strong>50.50</strong></span>The data model
should support the subclassing of membership via OpenACS
Relationships.</p>
</dd>
</dl></div><div class="variablelist"><dl class="variablelist">
<dt><span class="term">
<a name="groups-requirements-60-0" id="groups-requirements-60-0"></a><span class="strong"><strong>60.0
Composition</strong></span>
</span></dt><dd>
<p>A group <span class="strong"><strong>G<sub>C</sub>
</strong></span> is considered a
<span class="strong"><strong>component</strong></span> of a second
group <span class="strong"><strong>G<sub>P</sub>
</strong></span>
</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>when a direct composition relationship exists between
<span class="strong"><strong>G<sub>C</sub>
</strong></span> and
<span class="strong"><strong>G<sub>P</sub>
</strong></span>
</p></li><li class="listitem"><p>or when there exists a direct composition relationship between
<span class="strong"><strong>G<sub>C</sub>
</strong></span> and some
group <span class="strong"><strong>G<sub>i</sub>
</strong></span>
and <span class="strong"><strong>G<sub>i</sub>
</strong></span> has
a composition relationship with <span class="strong"><strong>G<sub>P</sub>
</strong></span>.</p></li>
</ul></div><p>
<span class="strong"><strong>60.10</strong></span>A group may be
a component of multiple groups.</p><p>
<span class="strong"><strong>60.20</strong></span>A group as a
component of itself is not supported.</p><p>
<span class="strong"><strong>60.30</strong></span>The data model
must support component constraints.</p><p>
<span class="strong"><strong>60.40</strong></span>The data model
should support the subclassing of composition via OpenACS
Relationships.</p>
</dd>
</dl></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-requirements-api" id="groups-requirements-api"></a>Requirements: API</h3></div></div></div><p>The API should let programmers accomplish the following
tasks:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><span class="strong"><strong>70.10 Create a
group</strong></span></span></dt><dd><p>The parties and groups system provides a well defined API call
that creates a new group by running the appropriate transactions on
the parties and groups system data model. This API is subject to
the constraints laid out in the data model.</p></dd><dt><span class="term"><span class="strong"><strong>70.20 Create a
person</strong></span></span></dt><dd><p>The parties and groups system provides a well defined API call
that creates a new person by running the appropriate transactions
on the parties and groups system data model. This API is subject to
the constraints laid out in the data model.</p></dd><dt><span class="term"><span class="strong"><strong>70.30 Create a
user</strong></span></span></dt><dd><p>The parties and groups system provides a well defined API call
that creates a new user by running the appropriate transactions on
the parties and groups system data model. This API is subject to
the constraints laid out in the data model.</p></dd><dt><span class="term"><span class="strong"><strong>80.10 Refine a
person to a user</strong></span></span></dt><dd><p>The parties and groups system provides a well defined API call
that creates a new user by running the appropriate transactions on
an existing person entity. This API is subject to the constraints
laid out in the data model.</p></dd><dt><span class="term"><span class="strong"><strong>80.30 Demote a
user to a person</strong></span></span></dt><dd><p>The parties and groups system provides a well defined API call
that demotes an existing user entity to a person entity by running
the appropriate transactions on the existing user. This API is
subject to the constraints laid out in the data model.</p></dd><dt><span class="term"><span class="strong"><strong>90.10 Update a
party</strong></span></span></dt><dd><p>The programmer should be able to modify, add, and delete
attributes on any party. This API is subject to the constraints
laid out in the data model.</p></dd><dt><span class="term"><span class="strong"><strong>95.10 Get the
attributes of a party</strong></span></span></dt><dd><p>The programmer should be able to view the attributes on any
party. This API is subject to the constraints laid out in the data
model.</p></dd><dt><span class="term"><span class="strong"><strong>100.10 Delete a
party</strong></span></span></dt><dd>
<p>The system provides an API for deleting a party. This API is
subject to the constraints laid out in the data model.</p><p>
<span class="strong"><strong>100.30</strong></span> The system
may provide a single API call to remove the party from all groups
and then delete the party.</p><p>
<span class="strong"><strong>100.40</strong></span> In the case
of a group, the system may provide a single API call to remove all
parties from a group and then delete the group.</p>
</dd><dt><span class="term"><span class="strong"><strong>110.0 Add a
party as a member of a group</strong></span></span></dt><dd><p>The parties and groups system provides an API for adding a party
as a member of a group. This API is subject to the constraints laid
out in the data model.</p></dd><dt><span class="term"><span class="strong"><strong>115.0 Add a
group as a component of a second group</strong></span></span></dt><dd><p>The parties and groups system provides an API for adding a group
as a component of a second group. This API is subject to the
constraints laid out in the data model.</p></dd><dt><span class="term"><span class="strong"><strong>120.0 Remove a
party as a member of a group</strong></span></span></dt><dd><p>The parties and groups system provides an API for deleting a
party&#39;s membership in a group. This API is subject to the
constraints laid out in the data model.</p></dd><dt><span class="term"><span class="strong"><strong>125.0 Remove a
group as a component of a second group</strong></span></span></dt><dd><p>The parties and groups system provides an API for deleting a
group&#39;s composition in a second group. This API is subject to
the constraints laid out in the data model.</p></dd><dt><span class="term"><span class="strong"><strong>130.0
Membership check</strong></span></span></dt><dd><p>The parties and groups system provides an API for answering the
question: "Is party <span class="strong"><strong>P</strong></span> a member of group <span class="strong"><strong>G</strong></span>?"</p></dd><dt><span class="term"><span class="strong"><strong>135.0
Composition check</strong></span></span></dt><dd><p>The parties and groups system provides an API for answering the
question: "Is group <span class="strong"><strong>G<sub>C</sub>
</strong></span> a component of group
<span class="strong"><strong>G<sub>P</sub>
</strong></span>?"</p></dd><dt><span class="term"><span class="strong"><strong>140.0 Get
members query</strong></span></span></dt><dd><p>The parties and groups system provides an API for answering the
question: "Which parties are members of group <span class="strong"><strong>G</strong></span>?"</p></dd><dt><span class="term"><span class="strong"><strong>145.0 Get
components query</strong></span></span></dt><dd><p>The parties and groups system provides an API for answering the
question: "Which groups are components of group <span class="strong"><strong>G</strong></span>?"</p></dd><dt><span class="term"><span class="strong"><strong>150.0
Member-of-groups query</strong></span></span></dt><dd><p>The parties and groups system provides an API for answering the
question: "Of which groups is party <span class="strong"><strong>P</strong></span> a member?"</p></dd><dt><span class="term"><span class="strong"><strong>155.0
Component-of-groups query</strong></span></span></dt><dd><p>The parties and groups system provides an API for answering the
question: "Of which groups is group <span class="strong"><strong>G</strong></span> a component?"</p></dd><dt><span class="term"><span class="strong"><strong>160.0 Allowed
membership check</strong></span></span></dt><dd><p>The parties and groups system provides an API for answering the
question: "Is party <span class="strong"><strong>P</strong></span> allowed to become a member of
group <span class="strong"><strong>G</strong></span>?"</p></dd><dt><span class="term"><span class="strong"><strong>165.0 Allowed
composition check</strong></span></span></dt><dd><p>The parties and groups system provides an API for answering the
question: "Is group <span class="strong"><strong>G<sub>C</sub>
</strong></span> allowed to become a
component of group <span class="strong"><strong>G<sub>P</sub>
</strong></span>?"</p></dd><dt><span class="term"><span class="strong"><strong>170.0
Efficiency</strong></span></span></dt><dd><p>Since many pages at a site may check membership in a group
before serving a page (e.g., as part of a general permissions
check), the data model must support the efficient storage and
retrieval of party attributes and membership.</p></dd><dt><span class="term"><span class="strong"><strong>180.0 Ease of
Use</strong></span></span></dt><dd><p>Since many SQL queries will check membership in a group as part
of the <code class="computeroutput">where</code> clause, whatever
mechanism is used to check membership in SQL should be fairly small
and simple.</p></dd>
</dl></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-requirements-ui" id="groups-requirements-ui"></a>Requirements: User Interface</h3></div></div></div><p>The user interface is a set of HTML pages that are used to drive
the underlying API. The user interface may provide the following
functions:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>200.0</strong></span> Create a
party</p></li><li class="listitem"><p>
<span class="strong"><strong>210.0</strong></span> View the
attributes of a party</p></li><li class="listitem"><p>
<span class="strong"><strong>220.0</strong></span> Update the
attributes of a party</p></li><li class="listitem"><p>
<span class="strong"><strong>240.0</strong></span> Delete a
party</p></li><li class="listitem"><p>
<span class="strong"><strong>250.0</strong></span> Add a party
to a group</p></li><li class="listitem"><p>
<span class="strong"><strong>260.0</strong></span> Remove a
party from a group</p></li><li class="listitem"><p>
<span class="strong"><strong>270.0</strong></span> Perform the
membership and composition checks outlined in 130.x to 165.x</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-requirements-rev-history" id="groups-requirements-rev-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>Document Revision
#</strong></span></td><td><span class="strong"><strong>Action Taken,
Notes</strong></span></td><td><span class="strong"><strong>When?</strong></span></td><td><span class="strong"><strong>By Whom?</strong></span></td>
</tr><tr>
<td>0.1</td><td>Creation</td><td>08/16/2000</td><td>Rafael Schloming</td>
</tr><tr>
<td>0.2</td><td>Initial revision</td><td>08/19/2000</td><td>Mark Thomas</td>
</tr><tr>
<td>0.3</td><td>Edited and reviewed, conforms to requirements template</td><td>08/23/2000</td><td>Kai Wu</td>
</tr><tr>
<td>0.4</td><td>Further revised, added UI requirements</td><td>08/24/2000</td><td>Mark Thomas</td>
</tr><tr>
<td>0.5</td><td>Final edits, pending freeze</td><td>08/24/2000</td><td>Kai Wu</td>
</tr><tr>
<td>0.6</td><td>More revisions, added composition requirements</td><td>08/30/2000</td><td>Mark Thomas</td>
</tr><tr>
<td>0.7</td><td>More revisions, added composition requirements</td><td>09/08/2000</td><td>Mark Thomas</td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="permissions-design" leftLabel="Prev" leftTitle="Permissions Design"
		    rightLink="groups-design" rightLabel="Next" rightTitle="Groups Design"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		