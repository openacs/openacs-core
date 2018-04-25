
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Groups Design}</property>
<property name="doc(title)">Groups Design</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="groups-requirements" leftLabel="Prev"
			title="Chapter 15. Kernel
Documentation"
			rightLink="subsites-requirements" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="groups-design" id="groups-design"></a>Groups Design</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By <a class="ulink" href="http://planitia.org" target="_top">Rafael H. Schloming</a> and
Mark Thomas</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-essentials" id="groups-design-essentials"></a>Essentials</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>User directory</p></li><li class="listitem"><p>Sitewide administrator directory</p></li><li class="listitem"><p>Subsite administrator directory</p></li><li class="listitem"><p>Tcl script directory</p></li><li class="listitem"><p><a class="xref" href="groups-requirements" title="Groups Requirements">OpenACS 4 Groups Requirements</a></p></li><li class="listitem"><p>Data model</p></li><li class="listitem">
<p>PL/SQL file</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p><a class="ulink" href="/doc/sql/display-sql?url=community-core-create.sql&amp;package_key=acs-kernel" target="_top">community-core-create.sql</a></p></li><li class="listitem"><p><a class="ulink" href="/doc/sql/display-sql?url=groups-create.sql&amp;package_key=acs-kernel" target="_top">groups-create.sql</a></p></li>
</ul></div>
</li><li class="listitem"><p>ER diagram</p></li><li class="listitem"><p>Transaction flow diagram</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-intro" id="groups-design-intro"></a>Introduction</h3></div></div></div><p>Almost all database-backed websites have users, and need to
model the grouping of users. The OpenACS 4 Parties and Groups
system is intended to provide the flexibility needed to model
complex real-world organizational structures, particularly to
support powerful subsite services; that is, where one OpenACS
installation can support what appears to the user as distinct web
services for different user communities.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-hist-considerations" id="groups-design-hist-considerations"></a>Historical
Considerations</h3></div></div></div><p>The primary limitation of the OpenACS 3.x user group system is
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
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-competitors" id="groups-design-competitors"></a>Competitive Analysis</h3></div></div></div><p>...</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-design-tradeoffs" id="groups-design-design-tradeoffs"></a>Design Tradeoffs</h3></div></div></div><p>The core of the Group Systems data model is quite simple, but it
was designed in the hopes of modeling "real world"
organizations which can be complex graph structures. The Groups
System only considers groups that can be modeled using directed
acyclic graphs, but queries over these structures are still complex
enough to slow the system down. Since almost every page will have
at least one membership check, a number of triggers, views, and
auxiliary tables have been created in the hopes of increasing
performance. To keep the triggers simple and the number of triggers
small, the data model disallows updates on the membership and
composition tables, only inserts and deletes are permitted.</p><p>The data model has tried to balance the need to model actual
organizations without making the system too complex or too slow.
The added triggers, views, and tables and will increase storage
requirements and the insert and delete times in an effort to speed
access time. The limited flexibility (no updates on membership)
trades against the complexity of the code.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-data-model" id="groups-design-data-model"></a>Data Model Discussion</h3></div></div></div><p>The Group System data model consists of the following
tables:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><code class="computeroutput">parties</code></span></dt><dd><p>The set of all defined parties: any <span class="emphasis"><em>person</em></span>, <span class="emphasis"><em>user</em></span>, or <span class="emphasis"><em>group</em></span> must have a corresponding row in
this table.</p></dd><dt><span class="term"><code class="computeroutput">persons</code></span></dt><dd><p>The set of all defined persons. To allow easy sorting of
persons, the name requirement <a class="link" href="groups-requirements">30.10</a> is
met by splitting the person&#39;s name into two columns:
<code class="computeroutput">first_names</code> and <code class="computeroutput">last_name</code>.</p></dd><dt><span class="term"><code class="computeroutput">users</code></span></dt><dd><p>The set of all registered users; this table includes information
about the user&#39;s email address and the user&#39;s visits to the
site.</p></dd><dt><span class="term"><code class="computeroutput">user_preferences</code></span></dt><dd><p>Preferences for the user.</p></dd><dt><span class="term"><code class="computeroutput">groups</code></span></dt><dd><p>The set of all defined groups.</p></dd><dt><span class="term"><code class="computeroutput">group_types</code></span></dt><dd><p>When a new type of group is created, this table holds additional
knowledge level attributes for the group and its subtypes.</p></dd><dt><span class="term"><code class="computeroutput">membership_rels</code></span></dt><dd><p>The set of direct membership relationships between a group and a
party.</p></dd><dt><span class="term"><code class="computeroutput">group_member_index</code></span></dt><dd><p>A mapping of a party <span class="strong"><strong>P</strong></span> to the groups {<span class="strong"><strong>G<sub>i</sub>
</strong></span>}the party is a
member of; this mapping includes the type of relationship by
including the appropriate<code class="computeroutput">rel_id</code>
from the <code class="computeroutput">membership_rels</code>
table.</p></dd><dt><span class="term"><code class="computeroutput">composition_rels</code></span></dt><dd><p>The set of direct component relationships between a group and
another group.</p></dd><dt><span class="term"><code class="computeroutput">group_component_index</code></span></dt><dd><p>A mapping of a group <span class="strong"><strong>G</strong></span>to the set of groups
{<span class="strong"><strong>G<sub>i</sub>
</strong></span>} that
<span class="strong"><strong>G</strong></span> is a component of;
this mapping includes the type of relationship by including the
appropriate<code class="computeroutput">rel_id</code> from the
<code class="computeroutput">composition_rels</code> table.</p></dd>
</dl></div><p>New groups are created through the <code class="computeroutput">group.new</code> constructor. When a specialized
type of group is required, the group type can be extended by an
application developer. Membership constraints can be specified at
creation time by passing a parent group to the constructor.</p><p>The <code class="computeroutput">membership_rels</code> and
<code class="computeroutput">composition_rels</code> tables
indicate a group&#39;s direct members and direct components; these
tables do not provide a record of the members or components that
are in the group by virtue of being a member or component of one of
the group&#39;s component groups. Site pages will query group
membership often, but the network of component groups can become a
very complex directed acyclic graph and traversing this graph for
every query will quickly degrade performance. To make membership
queries responsive, the data model includes triggers (described in
the next paragraph) which watch for changes in membership or
composition and update tables that maintain the group party
mappings, i.e., <code class="computeroutput">group_member_index</code> and <code class="computeroutput">group_component_index</code>. One can think of
these tables as a manually maintained index.</p><p>The following triggers keep the <code class="computeroutput">group_*_index</code> tables up to date:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><code class="computeroutput">membership_rels_in_tr</code></span></dt><dd><p>Is executed when a new group/member relationship is created (an
insert on <code class="computeroutput">membership_rels</code>)</p></dd><dt><span class="term"><code class="computeroutput">membership_rels_del_tr</code></span></dt><dd><p>Is executed when a group/member relationship is deleted (a
delete on <code class="computeroutput">membership_rels</code>)</p></dd><dt><span class="term"><code class="computeroutput">composition_rels_in_tr</code></span></dt><dd><p>Is executed when a new group/component relationship is created
(an insert on <code class="computeroutput">composition_rels</code>)</p></dd><dt><span class="term"><code class="computeroutput">composition_rels_del_tr</code></span></dt><dd><p>Is executed when a group/component relationship is deleted (a
delete on <code class="computeroutput">composition_rels</code>)</p></dd>
</dl></div><p>The data model provides the following views onto the
<code class="computeroutput">group_member_index</code> and
<code class="computeroutput">group_component_index</code> tables.
No code outside of Groups System should modify the <code class="computeroutput">group_*_index</code> tables.</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><code class="computeroutput">group_member_map</code></span></dt><dd><p>A mapping of a party to the groups the party is a member of;
this mapping includes the type of relationship by including the
appropriate<code class="computeroutput">rel_id</code> from the
<code class="computeroutput">membership_rels</code> table.</p></dd><dt><span class="term"><code class="computeroutput">group_approved_member_map</code></span></dt><dd><p>A mapping of a party to the groups the party is an approved
member of (<code class="computeroutput">member_state</code> is
'approved'); this mapping includes the type of relationship
by including the appropriate<code class="computeroutput">rel_id</code> from the <code class="computeroutput">membership_rels</code> table.</p></dd><dt><span class="term"><code class="computeroutput">group_distinct_member_map</code></span></dt><dd><p>A person may appear in the group member map multiple times, for
example, by being a member of two different groups that are both
components of a third group. This view is strictly a mapping of
<span class="strong"><strong>approved</strong></span> members to
groups.</p></dd><dt><span class="term"><code class="computeroutput">group_component_map</code></span></dt><dd><p>A mapping of a group <span class="strong"><strong>G</strong></span>to the set of groups
{<span class="strong"><strong>G<sub>i</sub>
</strong></span>} group
<span class="strong"><strong>G</strong></span> is a component of;
this mapping includes the type of relationship by including the
appropriate<code class="computeroutput">rel_id</code> from the
<code class="computeroutput">composition_rels</code> table.</p></dd><dt><span class="term"><code class="computeroutput">party_member_map</code></span></dt><dd><p>A mapping of a party <span class="strong"><strong>P</strong></span> to the set of parties
{<span class="strong"><strong>P<sub>i</sub>
</strong></span>} party
<span class="strong"><strong>P</strong></span> is a member of.</p></dd><dt><span class="term"><code class="computeroutput">party_approved_member_map</code></span></dt><dd><p>A mapping of a party <span class="strong"><strong>P</strong></span> to the set of parties
{<span class="strong"><strong>P<sub>i</sub>
</strong></span>} party
<span class="strong"><strong>P</strong></span> is an <span class="strong"><strong>approved</strong></span> member of.</p></dd>
</dl></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-api" id="groups-design-api"></a>API</h3></div></div></div><p>The API consists of tables and views and PL/SQL functions.</p><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="groups-design-tables-views" id="groups-design-tables-views"></a>Tables and Views</h4></div></div></div><p>The <code class="computeroutput">group_types</code> table is
used to create new types of groups.</p><p>The <code class="computeroutput">group_member_map</code>,
<code class="computeroutput">group_approved_member_map</code>,
<code class="computeroutput">group_distinct_member_map</code>,
<code class="computeroutput">group_component_map</code>,
<code class="computeroutput">party_member_map</code>, and
<code class="computeroutput">party_approved_member_map</code> views
are used to query group membership and composition.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="groups-design-pl-sql-api" id="groups-design-pl-sql-api"></a>PL/SQL API</h4></div></div></div><p><span class="strong"><strong>Person</strong></span></p><p>
<code class="computeroutput">person.new</code> creates a new
person and returns the <code class="computeroutput">person_id</code>. The function must be given the
full name of the person in two pieces: <code class="computeroutput">first_names</code> and <code class="computeroutput">last_name</code>. All other fields are optional
and default to null except for <code class="computeroutput">object_type</code> which defaults to person and
<code class="computeroutput">creation_date</code> which defaults to
<code class="computeroutput">sysdate</code>. The interface for this
function is:</p><pre class="programlisting">
function person.new (
  person_id          persons.person_id%TYPE,
  object_type        acs_objects.object_type%TYPE,
  creation_date      acs_objects.creation_date%TYPE,
  creation_user      acs_objects.creation_user%TYPE,
  creation_ip        acs_objects.creation_ip%TYPE,
  email              parties.email%TYPE,
  url                parties.url%TYPE,
  first_names        persons.first_names%TYPE,
  last_name          persons.last_name%TYPE
) return persons.person_id%TYPE;
</pre><p>
<code class="computeroutput">person.delete</code> deletes the
person whose <code class="computeroutput">person_id</code> is
passed to it. The interface for this procedure is:</p><pre class="programlisting">
procedure person.delete (
  person_id     persons.person_id%TYPE
);
</pre><p>
<code class="computeroutput">person.name</code> returns the name
of the person whose <code class="computeroutput">person_id</code>
is passed to it. The interface for this function is:</p><pre class="programlisting">
function person.name (
  person_id     persons.person_id%TYPE
) return varchar;
</pre><p><span class="strong"><strong>User</strong></span></p><p>
<code class="computeroutput">acs_user.new</code> creates a new
user and returns the <code class="computeroutput">user_id</code>.
The function must be given the user&#39;s email address and the
full name of the user in two pieces: <code class="computeroutput">first_names</code> and <code class="computeroutput">last_name</code>. All other fields are optional.
The interface for this function is:</p><pre class="programlisting">
function acs_user.new (
  user_id            users.user_id%TYPE,
  object_type        acs_objects.object_type%TYPE,
  creation_date      acs_objects.creation_date%TYPE,
  creation_user      acs_objects.creation_user%TYPE,
  creation_ip        acs_objects.creation_ip%TYPE,
  email              parties.email%TYPE,
  url                parties.url%TYPE,
  first_names        persons.first_names%TYPE,
  last_name          persons.last_name%TYPE
  password           users.password%TYPE,
  salt               users.salt%TYPE,
  password_question  users.password_question%TYPE,
  password_answer    users.password_answer%TYPE,
  screen_name        users.screen_name%TYPE,
  email_verified_p   users.email_verified_p%TYPE
) return users.user_id%TYPE;
</pre><p>
<code class="computeroutput">acs_user.delete</code> deletes the
user whose <code class="computeroutput">user_id</code> is passed to
it. The interface for this procedure is:</p><pre class="programlisting">
procedure acs_user.delete (
  user_id       users.user_id%TYPE
);
</pre><p>
<code class="computeroutput">acs_user.receives_alerts_p</code>
returns 't' if the user should receive email alerts and
'f' otherwise. The interface for this function is:</p><pre class="programlisting">
function acs_user.receives_alerts_p (
  user_id       users.user_id%TYPE
) return varchar;
</pre><p>Use the procedures <code class="computeroutput">acs_user.approve_email</code> and <code class="computeroutput">acs_user.unapprove_email</code> to specify whether
the user&#39;s email address is valid. The interface for these
procedures are:</p><pre class="programlisting">
procedure acs_user.approve_email (
  user_id       users.user_id%TYPE
);

procedure acs_user.unapprove_email (
  user_id       users.user_id%TYPE
);
</pre><p><span class="strong"><strong>Group</strong></span></p><p>
<code class="computeroutput">acs_group.new</code> creates a new
group and returns the <code class="computeroutput">group_id</code>.
All fields are optional and default to null except for <code class="computeroutput">object_type</code> which defaults to
'group', <code class="computeroutput">creation_date</code>
which defaults to <code class="computeroutput">sysdate</code>, and
<code class="computeroutput">group_name</code> which is required.
The interface for this function is:</p><pre class="programlisting">
function acs_group.new (
  group_id           groups.group_id%TYPE,
  object_type        acs_objects.object_type%TYPE,
  creation_date      acs_objects.creation_date%TYPE,
  creation_user      acs_objects.creation_user%TYPE,
  creation_ip        acs_objects.creation_ip%TYPE,
  email              parties.email%TYPE,
  url                parties.url%TYPE,
  group_name         groups.group_name%TYPE
) return groups.group_id%TYPE;
</pre><p>
<code class="computeroutput">acs_group.name</code> returns the
name of the group whose <code class="computeroutput">group_id</code> is passed to it. The interface for
this function is:</p><pre class="programlisting">
function acs_group.name (
  group_id      groups.group_id%TYPE
) return varchar;
</pre><p>
<code class="computeroutput">acs_group.member_p</code> returns
't' if the specified party is a member of the specified
group. Returns 'f' otherwise. The interface for this
function is:</p><pre class="programlisting">
function acs_group.member_p (
  group_id      groups.group_id%TYPE,
  party_id      parties.party_id%TYPE,
) return char;
</pre><p><span class="strong"><strong>Membership
Relationship</strong></span></p><p>
<code class="computeroutput">membership_rel.new</code> creates a
new membership relationship type between two parties and returns
the relationship type&#39;s <code class="computeroutput">rel_id</code>. All fields are optional and default
to null except for <code class="computeroutput">rel_type</code>
which defaults to membership_rel. The interface for this function
is:</p><pre class="programlisting">
function membership_rel.new (
  rel_id             membership_rels.rel_id%TYPE,
  rel_type           acs_rels.rel_type%TYPE,
  object_id_one      acs_rels.object_id_one%TYPE,
  object_id_two      acs_rels.object_id_two%TYPE,
  member_state       membership_rels.member_state%TYPE,
  creation_user      acs_objects.creation_user%TYPE,
  creation_ip        acs_objects.creation_ip%TYPE,
) return membership_rels.rel_id%TYPE;
</pre><p>
<code class="computeroutput">membership_rel.ban</code> sets the
<code class="computeroutput">member_state</code> of the given
<code class="computeroutput">rel_id</code> to 'banned'. The
interface for this procedure is:</p><pre class="programlisting">
procedure membership_rel.ban (
  rel_id           membership_rels.rel_id%TYPE
);
</pre><p>
<code class="computeroutput">membership_rel.approve</code> sets
the <code class="computeroutput">member_state</code> of the given
<code class="computeroutput">rel_id</code> to 'approved'.
The interface for this procedure is:</p><pre class="programlisting">
procedure membership_rel.approve (
  rel_id           membership_rels.rel_id%TYPE
);
</pre><p>
<code class="computeroutput">membership_rel.reject</code> sets
the <code class="computeroutput">member_state</code> of the given
<code class="computeroutput">rel_id</code> to 'rejected. The
interface for this procedure is:</p><pre class="programlisting">
procedure membership_rel.reject (
  rel_id           membership_rels.rel_id%TYPE
);
</pre><p>
<code class="computeroutput">membership_rel.unapprove</code>
sets the <code class="computeroutput">member_state</code> of the
given <code class="computeroutput">rel_id</code> to an empty string
''. The interface for this procedure is:</p><pre class="programlisting">
procedure membership_rel.unapprove (
  rel_id           membership_rels.rel_id%TYPE
);
</pre><p>
<code class="computeroutput">membership_rel.deleted</code> sets
the <code class="computeroutput">member_state</code> of the given
<code class="computeroutput">rel_id</code> to 'deleted'.
The interface for this procedure is:</p><pre class="programlisting">
procedure membership_rel.deleted (
  rel_id           membership_rels.rel_id%TYPE
);
</pre><p>
<code class="computeroutput">membership_rel.delete</code>
deletes the given <code class="computeroutput">rel_id</code>. The
interface for this procedure is:</p><pre class="programlisting">
procedure membership_rel.delete (
  rel_id           membership_rels.rel_id%TYPE
);
</pre><p><span class="strong"><strong>Composition
Relationship</strong></span></p><p>
<code class="computeroutput">composition_rel.new</code> creates
a new composition relationship type and returns the
relationship&#39;s <code class="computeroutput">rel_id</code>. All
fields are optional and default to null except for <code class="computeroutput">rel_type</code> which defaults to composition_rel.
The interface for this function is:</p><pre class="programlisting">
function membership_rel.new (
  rel_id             composition_rels.rel_id%TYPE,
  rel_type           acs_rels.rel_type%TYPE,
  object_id_one      acs_rels.object_id_one%TYPE,
  object_id_two      acs_rels.object_id_two%TYPE,
  creation_user      acs_objects.creation_user%TYPE,
  creation_ip        acs_objects.creation_ip%TYPE,
) return composition_rels.rel_id%TYPE;
</pre><p>
<code class="computeroutput">composition_rel.delete</code>
deletes the given <code class="computeroutput">rel_id</code>. The
interface for this procedure is:</p><pre class="programlisting">
procedure membership_rel.delete (
  rel_id           composition_rels.rel_id%TYPE
);
</pre>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-ui" id="groups-design-ui"></a>User Interface</h3></div></div></div><p>Describe the admin pages.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-config" id="groups-design-config"></a>Configuration/Parameters</h3></div></div></div><p>...</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-acc-tests" id="groups-design-acc-tests"></a>Acceptance Tests</h3></div></div></div><p>...</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-future" id="groups-design-future"></a>Future Improvements/Areas of Likely
Change</h3></div></div></div><p>...</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-authors" id="groups-design-authors"></a>Authors</h3></div></div></div><div class="variablelist"><dl class="variablelist">
<dt><span class="term">System creator</span></dt><dd><p><a class="ulink" href="mailto:rhs\@mit.edu" target="_top">Rafael
H. Schloming</a></p></dd><dt><span class="term">System owner</span></dt><dd><p><a class="ulink" href="mailto:rhs\@mit.edu" target="_top">Rafael
H. Schloming</a></p></dd><dt><span class="term">Documentation author</span></dt><dd><p>Mark Thomas</p></dd>
</dl></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="groups-design-rev-history" id="groups-design-rev-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><thead><tr>
<th><span class="strong"><strong>Document Revision
#</strong></span></th><th><span class="strong"><strong>Action Taken,
Notes</strong></span></th><th><span class="strong"><strong>When?</strong></span></th><th><span class="strong"><strong>By Whom?</strong></span></th>
</tr></thead><tbody>
<tr>
<td>0.1</td><td>Creation</td><td>08/22/2000</td><td><a class="ulink" href="mailto:rhs\@mit.edu" target="_top">Rafael
H. Schloming</a></td>
</tr><tr>
<td>0.2</td><td>Initial Revision</td><td>08/30/2000</td><td>Mark Thomas</td>
</tr><tr>
<td>0.3</td><td>Additional revisions; tried to clarify
membership/compostion</td><td>09/08/2000</td><td>Mark Thomas</td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="groups-requirements" leftLabel="Prev" leftTitle="Groups Requirements"
			rightLink="subsites-requirements" rightLabel="Next" rightTitle="Subsites Requirements"
			homeLink="index" homeLabel="Home" 
			upLink="kernel-doc" upLabel="Up"> 
		    