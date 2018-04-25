
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Parties in OpenACS}</property>
<property name="doc(title)">Parties in OpenACS</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="subsites" leftLabel="Prev"
			title="Chapter 11. Development
Reference"
			rightLink="permissions-tediously-explained" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="parties" id="parties"></a>Parties in OpenACS</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By <a class="ulink" href="http://planitia.org" target="_top">Rafael H.
Schloming</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="parties-intro" id="parties-intro"></a>Introduction</h3></div></div></div><p>While many applications must deal with individuals and many
applications must deal with groups, most applications must deal
with individuals <span class="emphasis"><em>or</em></span> groups.
It is often the case with such applications that both individuals
and groups are treated identically. Modelling individuals and
groups as specializations of one supertype is a practical way to
manage both. This concept is so mundane that there is no need to
invent special terminology. This supertype is called a
"party".</p><p>A classic example of the "party" supertype is evident
in address books. A typical address book might contain the address
of a doctor, grocery store, and friend. The first field in an entry
in the address book is not labeled a person or company, but a
"party".</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="parties-data-model" id="parties-data-model"></a>The Data Model</h3></div></div></div><p>The parties developer guide begins with an introduction to the
parties data model, since OpenACS community applications likely
require using it in some way.</p><p><span class="strong"><strong>Parties</strong></span></p><p>The central table in the parties data model is the parties table
itself. Every party has exactly one row in this table. Every party
has an optional unique email address and an optional url. A party
is an acs object, so permissions may be granted and revoked on
parties and auditing information is stored in the acs objects
table.</p><pre class="programlisting"><code class="computeroutput">
create table parties (
    party_id    not null
            constraint parties_party_id_fk references
            acs_objects (object_id)
            constraint parties_party_id_pk primary key,
    email       varchar(100)
            constraint parties_email_un unique,
    url     varchar(200)
);
</code></pre><p>The <code class="computeroutput">persons</code> and <code class="computeroutput">groups</code> tables extend the <code class="computeroutput">parties</code> table. A row in the persons table
represents the most generic form of individual modeled. An
individual need not be known to the system as a user. A user is a
further specialized form of an individual (discussed later). A row
in the groups table represents the most generic form of group
modeled, where a group is an aggregation of zero or more
individuals.</p><p><span class="strong"><strong>Persons</strong></span></p><p>If a party is an individual then there will be a row in the
persons table containing <code class="computeroutput">first_names</code> and <code class="computeroutput">last_name</code> for that individual. The primary
key of the persons table (<code class="computeroutput">person_id</code>) references the primary key of
the parties table (<code class="computeroutput">party_id</code>),
so that there is a corresponding row in the parties table when
there is a row in the persons table.</p><pre class="programlisting"><code class="computeroutput">create table persons (
    person_id   not null
            constraint persons_person_id_fk
            references parties (party_id)
            constraint persons_person_id_pk primary key,
    first_names varchar(100) not null,
    last_name   varchar(100) not null
);
</code></pre><p><span class="strong"><strong>Users</strong></span></p><p>The <code class="computeroutput">users</code> table is a more
specialized form of <code class="computeroutput">persons</code>
table. A row in <code class="computeroutput">users</code> table
represents an individual that has login access to the system. The
primary key of the users table references the primary key of the
persons table. This guarantees that if there is a row in
<code class="computeroutput">users</code> table then there must be
a corresponding row in <code class="computeroutput">persons</code>
and <code class="computeroutput">parties</code> tables.</p><p>Decomposing all the information associated with a user into the
four tables (acs_objects, parties, persons, users) has some
immediate benefits. For instance, it is possible to remove access
to a user from a live system by removing his entry from the users
table, while leaving the rest of his information present (i.e.
turning him from a user into a person).</p><p>Wherever possible the OpenACS data model references the
<code class="computeroutput">persons</code> or <code class="computeroutput">parties</code> table, <span class="strong"><strong>not</strong></span> the <code class="computeroutput">users</code> table. Developers should be careful
to only reference the users table in situations where it is clear
that the reference is to a user for all cases and not to any other
individual for any case.</p><pre class="programlisting"><code class="computeroutput">create table users (
    user_id         not null
                constraint users_user_id_fk
                references persons (person_id)
                constraint users_user_id_pk primary key,
    password        varchar(100),
    salt            varchar(100),
    screen_name     varchar(100)
                constraint users_screen_name_un
                unique,
    priv_name       integer default 0 not null,
    priv_email      integer default 5 not null,
    email_verified_p    char(1) default 't'
                constraint users_email_verified_p_ck
                check (email_verified_p in ('t', 'f')),
    email_bouncing_p    char(1) default 'f' not null
                constraint users_email_bouncing_p_ck
                check (email_bouncing_p in ('t','f')),
    no_alerts_until     date,
    last_visit      date,
    second_to_last_visit    date,
    n_sessions      integer default 1 not null,
    password_question   varchar(1000),
    password_answer     varchar(1000)
);
</code></pre><p><span class="strong"><strong>Groups</strong></span></p><p>The final piece of the parties data model is the groups data
model. A group is a specialization of a party that represents an
aggregation of zero or more other parties. The only extra
information directly associated with a group (beyond that in the
parties table) is the name of the group:</p><pre class="programlisting"><code class="computeroutput">create table groups (
    group_id    not null
            constraint groups_group_id_fk
            references parties (party_id)
            constraint groups_group_id_pk primary key,
    group_name  varchar(100) not null
);
</code></pre><p>There is another piece to the groups data model that records
relations between parties and groups.</p><p><span class="strong"><strong>Group Relations</strong></span></p><p>Two types of group relations are represented in the data model:
membership relations and composite relations. The full range of
sophisticated group structures that exist in the real world can be
modelled in OpenACS by these two relationship types.</p><p>Membership relations represent direct membership relation
between parties and groups. A party may be a "member" of
a group. Direct membership relations are common in administrative
practices, and do not follow basic set theory rules. If A is a
member of B, and B is a member of C, A is <span class="strong"><strong>not</strong></span> a member of C. Membership
relations are not transitive.</p><p>Composition relation represents composite relation between
<span class="emphasis"><em>two groups</em></span>. Composite
relation is transitive. That is, it works like memberships in set
theory. If A is a member of B, and B is a member of C, then A is a
member of C.</p><p>For example, consider the membership relations of Greenpeace,
and composite relations of a multinational corporation. Greenpeace,
an organization (ie. group), can have both individuals and
organizations (other groups) as members. Hence the membership
relation between groups and <span class="emphasis"><em>parties</em></span>. However, someone is not a
member of Greenpeace just because they are a member of a group that
is a member of Greenpeace. Now, consider a multinational
corporation (MC) that has a U.S. division and a Eurasian division.
A member of either the U.S. or Eurasian division is automatically a
member of the MC. In this situation the U.S. and Eurasian divisions
are "components" of the MC, i.e., membership <span class="emphasis"><em>is</em></span> transitive with respect to
composition. Furthermore, a member of a European (or other) office
of the MC is automatically a member of the MC.</p><p><span class="strong"><strong>Group
Membership</strong></span></p><p>Group memberships can be created and manipulated using the
membership_rel package. Only one membership object can be created
for a given group, party pair.</p><p>It is possible in some circumstances to make someone a member of
a group of which they are already a member. That is because the
model distinguishes between direct membership and indirect
membership (membership via some composite relationship). For
example, a person might be listed in a system as both an individual
(direct membership) and a member of a household (indirect
membership) at a video rental store.</p><pre class="programlisting"><code class="computeroutput">
# sql code
create or replace package membership_rel
as

  function new (
    rel_id      in membership_rels.rel_id%TYPE default null,
    rel_type        in acs_rels.rel_type%TYPE default 'membership_rel',
    object_id_one   in acs_rels.object_id_one%TYPE,
    object_id_two   in acs_rels.object_id_two%TYPE,
    member_state    in membership_rels.member_state%TYPE default null,
    creation_user   in acs_objects.creation_user%TYPE default null,
    creation_ip     in acs_objects.creation_ip%TYPE default null
  ) return membership_rels.rel_id%TYPE;

  procedure ban (
    rel_id  in membership_rels.rel_id%TYPE
  );

  procedure approve (
    rel_id  in membership_rels.rel_id%TYPE
  );

  procedure reject (
    rel_id  in membership_rels.rel_id%TYPE
  );

  procedure unapprove (
    rel_id  in membership_rels.rel_id%TYPE
  );

  procedure deleted (
    rel_id  in membership_rels.rel_id%TYPE
  );

  procedure delete (
    rel_id  in membership_rels.rel_id%TYPE
  );

end membership_rel;
/
show errors
</code></pre><p><span class="strong"><strong>Group
Composition</strong></span></p><p>Composition relations can be created or destroyed using the
composition_rel package. The only restriction on compositions is
that there cannot be a reference loop, i.e., a group cannot be a
component of itself either directly or indirectly. This constraint
is maintained for you by the API. So users do not see some random
PL/SQL error message, do not give them the option to create a
composition relation that would result in a circular reference.</p><pre class="programlisting"><code class="computeroutput">
# sql code
create or replace package composition_rel
as

  function new (
    rel_id      in composition_rels.rel_id%TYPE default null,
    rel_type        in acs_rels.rel_type%TYPE default 'composition_rel',
    object_id_one   in acs_rels.object_id_one%TYPE,
    object_id_two   in acs_rels.object_id_two%TYPE,
    creation_user   in acs_objects.creation_user%TYPE default null,
    creation_ip     in acs_objects.creation_ip%TYPE default null
  ) return composition_rels.rel_id%TYPE;

  procedure delete (
    rel_id  in composition_rels.rel_id%TYPE
  );

end composition_rel;
/
show errors
</code></pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="parties-views" id="parties-views"></a>Views</h3></div></div></div><p>The parties data model does a reasonable job of representing
many of the situations one is likely to encounter when modeling
organizational structures. We still need to be able to efficiently
answer questions like "what members are in this group and all
of its components?", and "of what groups is this party a
member either directly or indirectly?". Composition relations
allow you to describe an arbitrary Directed Acyclic Graph (DAG)
between a group and its components. For these reasons the party
system provides a bunch of views that take advantage of the
internal representation of group relations to answer questions like
these very quickly.</p><p>The <code class="computeroutput">group_component_map</code> view
returns all the subcomponents of a group including components of
sub components and so forth. The <code class="computeroutput">container_id</code> column is the <code class="computeroutput">group_id</code> of the group in which <code class="computeroutput">component_id</code> is directly contained. This
allows you to easily distinguish whether a component is a direct
component or an indirect component. If a component is a direct
component then <code class="computeroutput">group_id</code> will be
equal to <code class="computeroutput">container_id</code>. You can
think of this view as having a primary key of <code class="computeroutput">group_id</code>, <code class="computeroutput">component_id</code>, and <code class="computeroutput">container_id</code>. The <code class="computeroutput">rel_id</code> column points to the row in
<code class="computeroutput">acs_rels</code> table that contains
the relation object that relates <code class="computeroutput">component_id</code> to <code class="computeroutput">container_id</code>. The <code class="computeroutput">rel_id</code> might be useful for retrieving or
updating standard auditing info for the relation.</p><pre class="programlisting"><code class="computeroutput">create or replace view group_component_map
as select group_id, component_id, container_id, rel_id
...
</code></pre><p>The <code class="computeroutput">group_member_map</code> view is
similar to <code class="computeroutput">group_component_map</code>
except for membership relations. This view returns all membership
relations regardless of membership state.</p><pre class="programlisting"><code class="computeroutput">create or replace view group_member_map
as select group_id, member_id, container_id, rel_id
...
</code></pre><p>The <code class="computeroutput">group_approved_member_map</code> view is the same
as <code class="computeroutput">group_member_map</code> except it
only returns entries that relate to approved members.</p><pre class="programlisting"><code class="computeroutput">create or replace view group_approved_member_map
as select group_id, member_id, container_id, rel_id
...
</code></pre><p>The <code class="computeroutput">group_distinct_member_map</code> view is a useful
view if you do not care about the distinction between direct
membership and indirect membership. It returns all members of a
group including members of components --the transitive closure.</p><pre class="programlisting"><code class="computeroutput">create or replace view group_distinct_member_map
as select group_id, member_id
...
</code></pre><p>The <code class="computeroutput">party_member_map</code> view is
the same as <code class="computeroutput">group_distinct_member_map</code>, except it
includes the identity mapping. It maps from a party to the fully
expanded list of parties represented by that party including the
party itself. So if a party is an individual, this view will have
exactly one mapping that is from that party to itself. If a view is
a group containing three individuals, this view will have four rows
for that party, one for each member, and one from the party to
itself.</p><pre class="programlisting"><code class="computeroutput">create or replace view party_member_map
as select party_id, member_id
...
</code></pre><p>The <code class="computeroutput">party_approved_member_map</code> view is the same
as <code class="computeroutput">party_member_map</code> except that
when it expands groups, it only pays attention to approved
members.</p><pre class="programlisting"><code class="computeroutput">create or replace view party_approved_member_map
as select party_id, member_id
...
</code></pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="parties-extending-data-model" id="parties-extending-data-model"></a>Extending The Parties Data
Model</h3></div></div></div><p>The parties data model can represent some fairly sophisticated
real world situations. Still, it would be foolish to assume that
this data model is sufficiently efficient for every application.
This section describes some of the more common ways to extend the
parties data model.</p><p><span class="strong"><strong>Specializing
Users</strong></span></p><p>Some applications will want to collect more detailed information
for people using the system. If there can be only one such piece of
information per user, then it might make sense to create another
type of individual that is a further specialization of a user. For
example a Chess Club community web site might want to record the
most recent score for each user. In a situation like this it would
be appropriate to create a subtype of users, say chess_club_users.
This child table of the users table would have a primary key that
references the users table, thereby guaranteeing that each row in
the chess_club_users table has a corresponding row in each of the
users, persons, parties, and acs_objects tables. This child table
could then store any extra information relevant to the Chess Club
community.</p><p><span class="strong"><strong>Specializing
Groups</strong></span></p><p>If one were to build an intranet application on top of the party
system, it is likely that one would want to take advantage of the
systems efficient representation of sophisticated organizational
structures, but there would be much more specialized information
associated with each group. In this case it would make sense to
specialize the group party type into a company party type in the
same manner as Specializing Users.</p><p><span class="strong"><strong>Specializing Membership
Relations</strong></span></p><p>The final portion of the parties data model that is designed to
be extended is the membership relationship. Consider the intranet
example again. It is likely that a membership in a company would
have more information associated with it than a membership in an
ordinary group. An obvious example of this would be a salary. It is
exactly this need to be able to extend membership relations with
mutable pieces of state that drove us to include a single integer
primary key in what could be thought of as a pure relation. Because
a membership relation is an ordinary acs object with <a class="ulink" href="object-identity" target="_top">object
identity</a>, it is as easy to extend the membership relation to
store extra information as it is to extend the users table or the
groups table.</p><p><span class="cvstag">($&zwnj;Id: parties.xml,v 1.9 2006/09/25 20:32:37
byronl Exp $)</span></p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="subsites" leftLabel="Prev" leftTitle="Writing OpenACS Application Pages"
			rightLink="permissions-tediously-explained" rightLabel="Next" rightTitle="OpenACS Permissions Tediously
Explained"
			homeLink="index" homeLabel="Home" 
			upLink="dev-guide" upLabel="Up"> 
		    