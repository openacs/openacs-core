
<property name="context">{/doc/acs-core-docs {Documentation}} {OpenACS Permissions Tediously Explained}</property>
<property name="doc(title)">OpenACS Permissions Tediously Explained</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="parties" leftLabel="Prev"
		    title="
Chapter 11. Development Reference"
		    rightLink="object-identity" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="permissions-tediously-explained" id="permissions-tediously-explained"></a>OpenACS Permissions Tediously
Explained</h2></div></div></div><p>by Vadim Nasardinov. Modified and converted to Docbook XML by
Roberto Mello</p><p>The code has been modified since this document was written so it
is now out of date. See <a class="ulink" href="http://openacs.org/forums/message-view?message_id=121807" target="_top">this forum thread</a>.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-tedious-overview" id="permissions-tedious-overview"></a>Permissions Overview</h3></div></div></div><p><span class="strong"><strong>Who (<code class="computeroutput">grantee_id</code>) can do what (<code class="computeroutput">privilege</code>) on which object (<code class="computeroutput">object_id</code>).</strong></span></p><p>The general permissions system has a flexible (and relatively
complex) data model in OpenACS. Developers who have not had the
time to learn the internals of the data model may end up writing
seemingly correct code that crashes their system in weird ways.
This writeup is the result of my running into such a piece of code
and trying to understand exactly what went wrong. It is geared
towards developers who understand the general permissions system to
the extent that is described in the <a class="ulink" href="permissions" target="_top">Groups, Context, Permissions
documentation</a>, but who have not had the opportunity to take a
long, careful look at the system internals.</p><p>In OpenACS, most of the interesting tables are expected to
extend (subtype) the <code class="computeroutput">acs_objects</code> table, i.e. they are expected
to have an integer primary key column that references the
<code class="computeroutput">object_id</code> column of
<code class="computeroutput">acs_objects</code>.</p><a name="acs_objects" id="acs_objects"></a><pre class="programlisting">
create table <span class="bold"><strong>acs_objects</strong></span> (
      object_id             integer
          not null
          constraint acs_objects_pk primary key,
      object_type
          not null
          constraint acs_objects_object_type_fk references acs_object_types (object_type),
      context_id
          constraint acs_objects_context_id_fk references acs_objects(object_id),
      security_inherit_p          char(1) default 't'
          not null,
      constraint acs_objects_sec_inherit_p_ck
          check (security_inherit_p in ('t', 'f')),
      creation_user         integer,
      creation_date         date default sysdate not null,
      creation_ip           varchar2(50),
      last_modified         date default sysdate not null,
      modifying_user        integer,
      modifying_ip          varchar2(50),
      constraint acs_objects_context_object_un
          unique (context_id, object_id) disable
);
    
</pre><p>This means that items that want to use the features of the
OpenACS object system needs to have an entry in the <code class="computeroutput">acs_objects</code>. This allows developers to
define relationships between any two entities <span class="emphasis"><em>A</em></span> and <span class="emphasis"><em>B</em></span> by defining a relationship between
their corresponding entries in the <code class="computeroutput">acs_objects</code> table. One of the applications
of this powerful capability is the general permissions system.</p><p>At the heart of the permission system are two tables:
<code class="computeroutput">acs_privileges</code> and <code class="computeroutput">acs_permissions</code>.</p><a name="acs_privileges" id="acs_privileges"></a><pre class="programlisting">
  create table <span class="bold"><strong>acs_privileges</strong></span> (
      privilege           varchar2(100) not null
          constraint acs_privileges_pk primary key,
      pretty_name         varchar2(100),
      pretty_plural       varchar2(100)
  );
    
</pre><a name="acs_permissions" id="acs_permissions"></a><pre class="programlisting">
  create table <span class="bold"><strong>acs_permissions</strong></span> (
      object_id
          not null
          constraint acs_permissions_on_what_id_fk references <a class="xref" href="permissions-tediously-explained">acs_objects</a> (object_id),
      grantee_id
          not null
          constraint acs_permissions_grantee_id_fk references <a class="xref" href="permissions-tediously-explained">parties</a> (party_id),
      privilege
          not null
          constraint acs_permissions_priv_fk references <a class="xref" href="permissions-tediously-explained">acs_privileges</a> (privilege),
      constraint acs_permissions_pk
          primary key (object_id, grantee_id, privilege)
  );
    
</pre><p>The <code class="computeroutput">acs_privileges</code> table
stores named privileges like <span class="emphasis"><em>read</em></span>, <span class="emphasis"><em>write</em></span>, <span class="emphasis"><em>delete</em></span>, <span class="emphasis"><em>create</em></span>, and <span class="emphasis"><em>admin</em></span>. The <code class="computeroutput">acs_permissions</code> table stores assertions of
the form:</p><p>Who (<code class="computeroutput">grantee_id</code>) can do what
(<code class="computeroutput">privilege</code>) on which object
(<code class="computeroutput">object_id</code>).</p><p>The micromanaging approach to system security would be to
require application developers to store permission information
explicitly about every object, i.e. if the system has 100,000 and
1,000 users who have the <span class="emphasis"><em>read</em></span> privilege on all objects, then we
would need to store 100,000,000 entries of the form:</p><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col align="center" class="c1"><col align="center" class="c2"><col align="center" class="c3">
</colgroup><thead><tr>
<th align="center">object_id</th><th align="center">grantee_id</th><th align="center">privilege</th>
</tr></thead><tbody>
<tr>
<td align="center">object_id_1</td><td align="center">user_id_1</td><td align="center">'read'</td>
</tr><tr>
<td align="center">object_id_1</td><td align="center">user_id_2</td><td align="center">'read'</td>
</tr><tr><td colspan="3" align="center">...</td></tr><tr>
<td align="center">object_id_1</td><td align="center">user_id_n</td><td align="center">'read'</td>
</tr><tr>
<td align="center">object_id_2</td><td align="center">user_id_1</td><td align="center">'read'</td>
</tr><tr>
<td align="center">object_id_2</td><td align="center">user_id_2</td><td align="center">'read'</td>
</tr><tr><td colspan="3" align="center">...</td></tr><tr>
<td align="center">object_id_2</td><td align="center">user_id_n</td><td align="center">'read'</td>
</tr><tr><td colspan="3" align="center">...</td></tr><tr><td colspan="3" align="center">...</td></tr><tr>
<td align="center">object_id_m</td><td align="center">user_id_1</td><td align="center">'read'</td>
</tr><tr>
<td align="center">object_id_m</td><td align="center">user_id_2</td><td align="center">'read'</td>
</tr><tr><td colspan="3" align="center">...</td></tr><tr>
<td align="center">object_id_m</td><td align="center">user_id_n</td><td align="center">'read'</td>
</tr>
</tbody>
</table></div><p>Although quite feasible, this approach fails to take advantage
of the fact that objects in the system are commonly organized
hierarchally, and permissions usually follow the hierarchical
structure, so that if user <span class="emphasis"><em>X</em></span>
has the <span class="emphasis"><em>read</em></span> privilege on
object <span class="emphasis"><em>A</em></span>, she typically also
has the <span class="emphasis"><em>read</em></span> privilege on
all objects attached under <span class="emphasis"><em>A</em></span>.</p><p>The general permission system takes advantage of the
hierarchical organization of objects to unburden developers of the
necessity to explicitly maintain security information for every
single object. There are three kinds of hierarchies involved. These
are discussed in the following sections.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-tedious-context-hierarchy" id="permissions-tedious-context-hierarchy"></a>Context
Hierarchy</h3></div></div></div><p>Suppose objects <span class="emphasis"><em>A</em></span>,
<span class="emphasis"><em>B</em></span>, ..., and <span class="emphasis"><em>F</em></span> form the following hierarchy.</p><div class="table">
<a name="idp140216701192784" id="idp140216701192784"></a><p class="title"><b>Table 11.2. Context
Hierarchy Example</b></p><div class="table-contents"><table summary="Context Hierarchy Example" cellspacing="0" border="1">
<colgroup>
<col align="center" class="c1"><col align="center" class="c2"><col align="center" class="c3">
</colgroup><tbody>
<tr><td colspan="3" align="center">
<span class="bold"><strong>A</strong></span><p><code class="computeroutput">object_id=10</code></p>
</td></tr><tr>
<td colspan="2" align="center">
<span class="bold"><strong>B</strong></span><p><code class="computeroutput">object_id=20</code></p>
</td><td align="center">
<span class="bold"><strong>C</strong></span><p><code class="computeroutput">object_id=30</code></p>
</td>
</tr><tr>
<td align="center">
<span class="bold"><strong>D</strong></span><p><code class="computeroutput">object_id=40</code></p>
</td><td align="center">
<span class="bold"><strong>E</strong></span><p><code class="computeroutput">object_id=50</code></p>
</td><td align="center">
<span class="bold"><strong>F</strong></span><p><code class="computeroutput">object_id=60</code></p>
</td>
</tr>
</tbody>
</table></div>
</div><br class="table-break"><p>This can be represented in the <a class="xref" href="permissions-tediously-explained">acs_objects</a>
table by the following entries:</p><div class="table">
<a name="idp140216701162992" id="idp140216701162992"></a><p class="title"><b>Table 11.3. acs_objects
example data</b></p><div class="table-contents"><table summary="acs_objects example data" cellspacing="0" border="1">
<colgroup>
<col align="center" class="c1"><col align="center" class="c2">
</colgroup><thead><tr>
<th align="center">object_id</th><th align="center">context_id</th>
</tr></thead><tbody>
<tr>
<td align="center">20</td><td align="center">10</td>
</tr><tr>
<td align="center">30</td><td align="center">10</td>
</tr><tr>
<td align="center">40</td><td align="center">20</td>
</tr><tr>
<td align="center">50</td><td align="center">20</td>
</tr><tr>
<td align="center">60</td><td align="center">30</td>
</tr>
</tbody>
</table></div>
</div><br class="table-break"><p>The first entry tells us that object 20 is the descendant of
object 10, and the third entry shows that object 40 is the
descendant of object 20. By running a <a class="ulink" href="http://www.oradoc.com/ora817/server.817/a85397/expressi.htm#1023748" target="_top">CONNECT BY</a> query, we can compute that object 40
is the second-generation descendant of object 10. With this in
mind, if we want to record the fact that user Joe has the
<span class="emphasis"><em>read</em></span> privilege on objects
<span class="emphasis"><em>A</em></span>, ..., <span class="emphasis"><em>F</em></span>, we only need to record one entry in
the <a class="xref" href="permissions-tediously-explained">acs_permissions</a>
table.</p><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col align="center" class="c1"><col align="center" class="c2"><col align="center" class="c3">
</colgroup><thead><tr>
<th align="center">object</th><th align="center">grantee</th><th align="center">privilege</th>
</tr></thead><tbody><tr>
<td align="center">A</td><td align="center">Joe</td><td align="center">read</td>
</tr></tbody>
</table></div><p>The fact that Joe can also read <span class="emphasis"><em>B</em></span>, <span class="emphasis"><em>C</em></span>, ..., and <span class="emphasis"><em>F</em></span> can be derived by ascertaining that
these objects are children of <span class="emphasis"><em>A</em></span> by traversing the context hierarchy.
As it turns out, hierarchical queries are expensive. As Rafael
Schloming put it so aptly, <span class="emphasis"><em>Oracle can't
deal with hierarchies for shit.</em></span>
</p><p>One way to solve this problem is to cache a flattened view of
the context tree like so:</p><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col align="center" class="c1"><col align="center" class="c2"><col align="center" class="c3">
</colgroup><thead><tr>
<th align="center">object</th><th align="center">ancestor</th><th align="center">n_generations</th>
</tr></thead><tbody>
<tr>
<td align="center">A</td><td align="center">A</td><td align="center">0</td>
</tr><tr>
<td align="center">B</td><td align="center">B</td><td align="center">0</td>
</tr><tr>
<td align="center">B</td><td align="center">A</td><td align="center">1</td>
</tr><tr>
<td align="center">C</td><td align="center">C</td><td align="center">0</td>
</tr><tr>
<td align="center">C</td><td align="center">A</td><td align="center">1</td>
</tr><tr>
<td align="center">D</td><td align="center">D</td><td align="center">0</td>
</tr><tr>
<td align="center">D</td><td align="center">B</td><td align="center">1</td>
</tr><tr>
<td align="center">D</td><td align="center">A</td><td align="center">2</td>
</tr><tr>
<td align="center">E</td><td align="center">E</td><td align="center">0</td>
</tr><tr>
<td align="center">E</td><td align="center">B</td><td align="center">1</td>
</tr><tr>
<td align="center">E</td><td align="center">A</td><td align="center">2</td>
</tr><tr>
<td align="center">F</td><td align="center">F</td><td align="center">0</td>
</tr><tr>
<td align="center">F</td><td align="center">C</td><td align="center">1</td>
</tr><tr>
<td align="center">F</td><td align="center">A</td><td align="center">2</td>
</tr>
</tbody>
</table></div><p>Note that the number of entries in the flattened view grows
exponentially with respect to the depth of the context tree. For
instance, if you have a fully populated binary tree with a depth of
<span class="emphasis"><em>n</em></span>, then the number of
entries in its flattened view is</p><p>1 + 2*2 + 3*4 + 4*8 + 5*16 + ... + (n+1)*2<sup>n</sup> =
n*2<sup>n+1</sup> + 1</p><p>Despite its potentially great storage costs, maintaining a
flattened representation of the context tree is exactly what
OpenACS does. The flattened context tree is stored in the
<code class="computeroutput">acs_object_context_index</code>
table.</p><a name="acs_object_context_index" id="acs_object_context_index"></a><pre class="programlisting">
  create table <span class="bold"><strong>acs_object_context_index</strong></span> (
      object_id
          not null
          constraint acs_obj_context_idx_obj_id_fk references <a class="xref" href="permissions-tediously-explained">acs_objects</a> (object_id),
      ancestor_id
          not null
          constraint acs_obj_context_idx_anc_id_fk references <a class="xref" href="permissions-tediously-explained">acs_objects</a> (object_id),
      n_generations         integer
          not null
          constraint acs_obj_context_idx_n_gen_ck check (n_generations <span class="markup">&gt;</span>= 0),
      constraint acs_object_context_index_pk
          primary key (object_id, ancestor_id)
  ) organization index;
    
</pre><p>A few things to note about this table are these. Number one, it
is an <a class="ulink" href="http://www.oradoc.com/ora817/server.817/a85397/statem3e.htm#2061922" target="_top">index-organized table</a>, which means it is
substantially optimized for access by primary key. Number two, as
the above computations suggest, the size of the table grows
<span class="strong"><strong>polynomially</strong></span> with
respect to the average number of descendants that an object has,
and <span class="strong"><strong>exponentially</strong></span> with
respect to the depth of the context tree.</p><p>The <code class="computeroutput">acs_object_context_index</code>
is kept in sync with the <a class="xref" href="permissions-tediously-explained">acs_objects</a>
table by triggers like this:</p><pre class="programlisting">
create or replace trigger acs_objects_context_id_in_tr
after insert on <a class="xref" href="permissions-tediously-explained">acs_objects</a>
for each row
begin
    insert into <a class="xref" href="permissions-tediously-explained">acs_object_context_index</a>
     (object_id, ancestor_id, n_generations)
    values
     (:new.object_id, :new.object_id, 0);

    if :new.context_id is not null and :new.security_inherit_p = 't' then
      insert into <a class="xref" href="permissions-tediously-explained">acs_object_context_index</a>
       (object_id, ancestor_id,
        n_generations)
      select
       :new.object_id as object_id, ancestor_id,
       n_generations + 1 as n_generations
      from <a class="xref" href="permissions-tediously-explained">acs_object_context_index</a>
      where object_id = :new.context_id;
    elsif :new.object_id != 0 then
      -- 0 is the id of the security context root object
      insert into <a class="xref" href="permissions-tediously-explained">acs_object_context_index</a>
       (object_id, ancestor_id, n_generations)
      values
       (:new.object_id, 0, 1);
    end if;
end;
</pre><p>One final note about <a class="xref" href="permissions-tediously-explained">acs_objects</a>.
By setting an object's <code class="computeroutput">security_inherit_p</code> column to 'f', you can
stop permissions from cascading down the context tree. In the
following example, Joe does not have the read permissions on
<span class="emphasis"><em>C</em></span> and <span class="emphasis"><em>F</em></span>.</p><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col align="center" class="c1"><col align="center" class="c2"><col align="center" class="c3">
</colgroup><tbody>
<tr><td colspan="3" align="center"><div class="literallayout"><p>
<br><span class="bold"><strong>A</strong></span><br><code class="computeroutput">object_id=10</code><br><span class="emphasis"><em>readable by Joe</em></span><br>

      </p></div></td></tr><tr>
<td colspan="2" align="center"><div class="literallayout"><p>
<br><span class="bold"><strong>B</strong></span><br><code class="computeroutput">object_id=20</code><br><span class="emphasis"><em>readable by Joe</em></span><br>

              </p></div></td><td align="center"><div class="literallayout"><p>
<br><span class="bold"><strong>C</strong></span><br><code class="computeroutput">object_id=30</code><br>
security_inherit_p = 'f'<br><span class="emphasis"><em>not readable by Joe</em></span><br>

      </p></div></td>
</tr><tr>
<td align="center"><div class="literallayout"><p>
<br><span class="bold"><strong>D</strong></span><br><code class="computeroutput">object_id=40</code><br>
      </p></div></td><td align="center"><div class="literallayout"><p>
<br><span class="bold"><strong>E</strong></span><br><code class="computeroutput">object_id=50</code><br>
      </p></div></td><td align="center"><div class="literallayout"><p>
<br><span class="bold"><strong>F</strong></span><br><code class="computeroutput">object_id=60</code><br>
security_inherit_p = 'f'<br><span class="emphasis"><em>not readable by Joe</em></span><br>

      </p></div></td>
</tr>
</tbody>
</table></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-tedious-privilege-hierarchy" id="permissions-tedious-privilege-hierarchy"></a>Privilege
Hierarchy</h3></div></div></div><p>Privileges are also organized hierarchically. In addition to the
five main system privileges defined in the ACS Kernel data model,
application developers may define their own. Note, however, that
this is no longer recommended practice.</p><p>By defining parent-child relationship between privileges, the
OpenACS data model makes it easier for developers to manage
permissions. Instead of granting a user explicit <span class="emphasis"><em>read</em></span>, <span class="emphasis"><em>write</em></span>, <span class="emphasis"><em>delete</em></span>, and <span class="emphasis"><em>create</em></span> privileges on an object, it is
sufficient to grant the user the <span class="emphasis"><em>admin</em></span> privilege to which the first four
privileges are tied. Privileges are structured as follows.</p><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col align="center" class="c1"><col align="center" class="c2"><col align="center" class="c3"><col align="center" class="c4">
</colgroup><tbody>
<tr><td colspan="4" align="center">admin</td></tr><tr>
<td align="center">create</td><td align="center">delete</td><td align="center">read</td><td align="center">write</td>
</tr>
</tbody>
</table></div><p>Note that <code class="computeroutput">admin</code> privileges
are greater than read, write, create and delete privileges
combined. Issuing someone read, write, create and delete privileges
will not result in the person getting <code class="computeroutput">admin</code> privileges.</p><p>The parent-child relationship between privileges is represented
in the <code class="computeroutput">acs_privilege_hierarchy</code>
table:</p><a name="acs_privilege_hierarchy" id="acs_privilege_hierarchy"></a><pre class="programlisting">
  create table <span class="bold"><strong>acs_privilege_hierarchy</strong></span> (
      privilege
          not null
          constraint acs_priv_hier_priv_fk references <a class="xref" href="permissions-tediously-explained">acs_privileges</a> (privilege),
      child_privilege
          not null
          constraint acs_priv_hier_child_priv_fk references <a class="xref" href="permissions-tediously-explained">acs_privileges</a> (privilege),
      constraint acs_privilege_hierarchy_pk
          primary key (privilege, child_privilege)
  );
    
</pre><p>As in the case of the context hierarchy, it is convenient to
have a flattened representation of this hierarchal structure. This
is accomplished by defining the following view.</p><a name="acs_privilege_descendant_map" id="acs_privilege_descendant_map"></a><pre class="programlisting">
  create or replace view <span class="bold"><strong>acs_privilege_descendant_map</strong></span>
  as
  select
    p1.privilege,
    p2.privilege as descendant
  from
    <a class="xref" href="permissions-tediously-explained">acs_privileges</a> p1,
    <a class="xref" href="permissions-tediously-explained">acs_privileges</a> p2
  where
    p2.privilege in 
      (select
         child_privilege
       from
         <a class="xref" href="permissions-tediously-explained">acs_privilege_hierarchy</a>
       start with
         privilege = p1.privilege
       connect by
         prior child_privilege = privilege
      )
    or p2.privilege = p1.privilege;
    
</pre><p>As the number of different privileges in the system is expected
to be reasonably small, there is no pressing need to cache the
flattened ansector-descendant view of the privilege hierarchy in a
specially maintained table like it is done in the case of the
context hierarchy.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-tedious-party-hierarchy" id="permissions-tedious-party-hierarchy"></a>Party Hierarchy</h3></div></div></div><p>Now for the third hierarchy playing a promiment role in the
permission system. The party data model is set up as follows.</p><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col align="center" class="c1"><col align="center" class="c2">
</colgroup><tbody>
<tr><td colspan="2" align="center"><a class="xref" href="permissions-tediously-explained">parties</a></td></tr><tr>
<td align="center"><a class="xref" href="permissions-tediously-explained">persons</a></td><td rowspan="2" align="center" valign="top"><a class="xref" href="permissions-tediously-explained">groups</a></td>
</tr><tr><td align="center"><a class="xref" href="permissions-tediously-explained">users</a></td></tr>
</tbody>
</table></div><a name="tedious-parties" id="tedious-parties"></a><pre class="programlisting">
  create table <span class="bold"><strong>parties</strong></span> (
      party_id
          not null
          constraint parties_party_id_fk references <a class="xref" href="permissions-tediously-explained">acs_objects</a> (object_id)
          constraint parties_pk primary key,
      email               varchar2(100)
          constraint parties_email_un unique,
      url                 varchar2(200)
  );
    
</pre><a name="persons" id="persons"></a><pre class="programlisting">
  create table <span class="bold"><strong>persons</strong></span> (
      person_id
          not null
          constraint persons_person_id_fk references <a class="xref" href="permissions-tediously-explained">parties</a> (party_id)
          constraint persons_pk primary key,
      first_names          varchar2(100)
          not null,
      last_name            varchar2(100)
          not null
  );
    
</pre><a name="users" id="users"></a><pre class="programlisting">
  create table <span class="bold"><strong>users</strong></span> (
      user_id
          not null
          constraint users_user_id_fk references <a class="xref" href="permissions-tediously-explained">persons</a> (person_id)
          constraint users_pk primary key,
      password        char(40),
      -- other attributes
  );
    
</pre><a name="groups" id="groups"></a><pre class="programlisting">
 
  create table <span class="bold"><strong>groups</strong></span> (
      group_id
          not null
          constraint groups_group_id_fk references <a class="xref" href="permissions-tediously-explained">parties</a> (party_id)
          constraint groups_pk primary key,
      group_name           varchar2(100) not null
  );
    
</pre><p>Recall that the <code class="computeroutput">grantee_id</code>
column of the <a class="xref" href="permissions-tediously-explained">acs_permissions</a>
table references <code class="computeroutput">parties.party_id</code>. This means that you can
grant a privilege on an object to a party, person, user, or group.
Groups represent aggregations of parties. The most common scenario
that you are likely to encounter is a group that is a collection of
users, although you could also have collections of persons, groups,
parties, or any mix thereof.</p><p>Given that the most common use of groups is to partition users,
how do you build groups? One way is to grant membership explicitly.
If you have a group named <span class="emphasis"><em>Pranksters</em></span>, you can assign membership to
Pete, Poly, and Penelope. The fact that these users are members of
the <span class="emphasis"><em>Pranksters</em></span> group will be
recorded in the <code class="computeroutput">membership_rels</code>
and <code class="computeroutput">acs_rels</code> tables:</p><a name="acs_rels" id="acs_rels"></a><pre class="programlisting">
  create table <span class="bold"><strong>acs_rels</strong></span> (
      rel_id
          not null
          constraint acs_rels_rel_id_fk references <a class="xref" href="permissions-tediously-explained">acs_objects</a> (object_id)
          constraint acs_rels_pk primary key,
      rel_type
          not null
          constraint acs_rels_rel_type_fk references acs_rel_types (rel_type),
      object_id_one
          not null
          constraint acs_object_rels_one_fk references <a class="xref" href="permissions-tediously-explained">acs_objects</a> (object_id),
      object_id_two
          not null
          constraint acs_object_rels_two_fk references <a class="xref" href="permissions-tediously-explained">acs_objects</a> (object_id),
      constraint acs_object_rels_un
          unique (rel_type, object_id_one, object_id_two)
  );
    
</pre><a name="membership_rels" id="membership_rels"></a><pre class="programlisting">
  create table <span class="bold"><strong>membership_rels</strong></span> (
      rel_id
          constraint membership_rel_rel_id_fk references <a class="xref" href="permissions-tediously-explained">acs_rels</a> (rel_id)
          constraint membership_rel_rel_id_pk primary key,
      -- null means waiting for admin approval
      member_state         varchar2(20)
          constraint membership_rel_mem_ck
           check (member_state in ('approved', 'banned', 'rejected', 'deleted'))
  );
    
</pre><p>The <a class="xref" href="permissions-tediously-explained">acs_rels</a> table
entries would look like so:</p><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col align="center" class="c1"><col align="center" class="c2"><col align="center" class="c3">
</colgroup><thead><tr>
<th align="center"><code class="computeroutput">rel_type</code></th><th align="center"><code class="computeroutput">object_one</code></th><th align="center"><code class="computeroutput">object_two</code></th>
</tr></thead><tbody>
<tr>
<td align="center">membership_rel</td><td align="center">Pranksters</td><td align="center">Pete</td>
</tr><tr>
<td align="center">membership_rel</td><td align="center">Pranksters</td><td align="center">Poly</td>
</tr><tr>
<td align="center">membership_rel</td><td align="center">Pranksters</td><td align="center">Penelope</td>
</tr>
</tbody>
</table></div><p>Read <code class="computeroutput">acs_rels</code>: right-side is
a subset of left-side, ie <code class="computeroutput">object2</code> is a part of <code class="computeroutput">object1</code>.</p><p>Another way of building up groups is by adding subgroups.
Suppose we define <span class="emphasis"><em>Merry
Pranksters</em></span> and <span class="emphasis"><em>Sad
Pranksters</em></span> as subgroups of <span class="emphasis"><em>Pranksters</em></span>. We say that the <span class="emphasis"><em>Pranksters</em></span> group is <span class="strong"><strong>composed</strong></span> of groups <span class="emphasis"><em>Merry Pranksters</em></span> and <span class="emphasis"><em>Sad Pranksters</em></span>. This information is
stored in the <a class="xref" href="permissions-tediously-explained">acs_rels</a> and
<code class="computeroutput">composition_rels</code> tables.</p><a name="composition_rels" id="composition_rels"></a><pre class="programlisting">
create table <span class="bold"><strong>composition_rels</strong></span> (
    rel_id
        constraint composition_rels_rel_id_fk references <a class="xref" href="permissions-tediously-explained">acs_rels</a> (rel_id)
        constraint composition_rels_rel_id_pk primary key
);
    
</pre><p>The relevant entries in the <a class="xref" href="permissions-tediously-explained">acs_rels</a> look
like so.</p><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col align="center" class="c1"><col align="center" class="c2"><col align="center" class="c3">
</colgroup><thead><tr>
<th align="center"><code class="computeroutput">rel_type</code></th><th align="center"><code class="computeroutput">object_one</code></th><th align="center"><code class="computeroutput">object_two</code></th>
</tr></thead><tbody>
<tr>
<td align="center">composition_rel</td><td align="center">Pranksters</td><td align="center">Merry Pranksters</td>
</tr><tr>
<td align="center">composition_rel</td><td align="center">Pranksters</td><td align="center">Sad Pranksters</td>
</tr>
</tbody>
</table></div><p>The composition relationship means that if I add Matt, Mel, and
Mary to the <span class="emphasis"><em>Merry
Pranksters</em></span>, they should also automatically become
members of the <span class="emphasis"><em>Pranksters</em></span>
group. The situation we are facing in trying to determine whether
or not a user is member of a group is similar to the one discussed
above in the case of the context hierarchy. Groups can form
hierarchies with respect to the composition relationship. The
compositon relationship is transitive. If <span class="emphasis"><em>G1</em></span> is a subgroup of <span class="emphasis"><em>G2</em></span>, and <span class="emphasis"><em>G2</em></span> is a subgroup of <span class="emphasis"><em>G3</em></span>, then <span class="emphasis"><em>G1</em></span> is a subgroup of <span class="emphasis"><em>G3</em></span>; that is, any member of <span class="emphasis"><em>G1</em></span> is also a member of <span class="emphasis"><em>G3</em></span>.</p><p>Traversing the group composition hierarchy requires running
<a class="ulink" href="http://www.oradoc.com/ora817/server.817/a85397/expressi.htm#1023748" target="_top">hierarchical queries</a>, which are expensive in
Oracle. As we saw in the <span class="emphasis"><em>Context
Hierarchy</em></span> section, one way of reducing the performance
hit incurred by hierarchical queries is to cache query results in a
table maintained by triggers. The OpenACS data model defines two
such tables:</p><a name="group_component_index" id="group_component_index"></a><pre class="programlisting">
 create table <span class="bold"><strong>group_component_index</strong></span> (
          group_id        not null
                          constraint group_comp_index_group_id_fk
                          references <a class="xref" href="permissions-tediously-explained">groups</a> (group_id),
          component_id    not null
                          constraint group_comp_index_comp_id_fk
                          references <a class="xref" href="permissions-tediously-explained">groups</a> (group_id),
          rel_id          not null
                          constraint group_comp_index_rel_id_fk
                          references composition_rels (rel_id),
          container_id    not null
                          constraint group_comp_index_cont_id_ck
                          references <a class="xref" href="permissions-tediously-explained">groups</a> (group_id),
          constraint group_component_index_ck
          check (group_id != component_id),
          constraint group_component_index_pk
          primary key (group_id, component_id, rel_id)
  ) organization index;
    
</pre><a name="group_member_index" id="group_member_index"></a><pre class="programlisting">
  create table <span class="bold"><strong>group_member_index</strong></span> (
      group_id
          not null
          constraint group_member_index_grp_id_fk references <a class="xref" href="permissions-tediously-explained">groups</a> (group_id),
      member_id
          not null
          constraint group_member_index_mem_id_fk references <a class="xref" href="permissions-tediously-explained">parties</a> (party_id),
      rel_id
          not null
          constraint group_member_index_rel_id_fk references <a class="xref" href="permissions-tediously-explained">membership_rels</a> (rel_id),
      container_id
          not null
          constraint group_member_index_cont_id_fk references <a class="xref" href="permissions-tediously-explained">groups</a> (group_id),
      constraint group_member_index_pk
          primary key (member_id, group_id, rel_id)
  ) organization index;
    
</pre><p>The <code class="computeroutput">group_component_index</code>
table stores a flattened representation of the group composition
hierarchy that is maintained in sync with the <a class="xref" href="permissions-tediously-explained">acs_rels</a> and
<code class="computeroutput">composition_rels</code> tables through
triggers.</p><p><span class="strong"><strong>additional
comments</strong></span></p><p>As far as the <code class="computeroutput">group_member_index</code> table goes, I am not
sure I understand its purpose. It maintains group-member
relationships that are resolved with respect to group composition.
Note that information stored in <a class="xref" href="permissions-tediously-explained">group_member_index</a>
can be trivially derived by joining <a class="xref" href="permissions-tediously-explained">membership_rels</a>,
<a class="xref" href="permissions-tediously-explained">acs_rels</a>, and
<a class="xref" href="permissions-tediously-explained">group_component_index</a>.
Here is a view that does it. (This view is <span class="emphasis"><em>not</em></span> part of the OpenACS Kernel data
model.)</p><pre class="programlisting">
create or replace view group_member_view
as
select
  gci.group_id, r.object_id_two as member_id
from
  (
   select
     group_id, group_id as component_id
   from
     <a class="xref" href="permissions-tediously-explained">groups</a>
   union
   select
     group_id, component_id
   from
     group_component_index
  ) gci,
  <a class="xref" href="permissions-tediously-explained">membership_rels</a> mr,
  <a class="xref" href="permissions-tediously-explained">acs_rels</a> r
where
  mr.rel_id = r.rel_id
  and r.object_id_one = gci.component_id;
    
</pre><p>A heuristic way to verify that <code class="computeroutput">group_member_view</code> is essentially identical
to <a class="xref" href="permissions-tediously-explained">group_member_index</a>
is to compute the symmetric difference between the two:</p><pre class="programlisting">
select
  group_id, member_id
from
  (
   select group_id, member_id from group_member_view
   minus
   select group_id, member_id from <a class="xref" href="permissions-tediously-explained">group_member_index</a>
  )
union
select
  group_id, member_id
from
  (
   select group_id, member_id from <a class="xref" href="permissions-tediously-explained">group_member_index</a>
   minus
   select group_id, member_id from group_member_view
  )
    
</pre><p>The query returns no rows. The important point is, if we have a
flattened view of the composition hierarchy -- like one provided by
the <a class="xref" href="permissions-tediously-explained">group_component_index</a>
table -- membership relationship resolution can be computed
trivially with no hierarchical queries involved. There is no need
to keep the view in a denormalized table, unless doing so results
in substantial performance gains.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-tedious-putting-all-together" id="permissions-tedious-putting-all-together"></a>Putting It All
Together</h3></div></div></div><p>Security information is queried by calling the <code class="computeroutput">acs_permission.permission_p</code> function in
OpenACS. This is accessible from Tcl via the <code class="computeroutput">permission::permission_p</code> procedure.</p><pre class="programlisting">
  
  create or replace package body acs_permission
  as
    -- some stuff removed for the sake of brevity
  
    function <span class="bold"><strong>permission_p</strong></span> (
      object_id  acs_objects.object_id%TYPE,
      party_id   parties.party_id%TYPE,
      privilege  acs_privileges.privilege%TYPE
    ) return char
    as
      exists_p char(1);
    begin
      -- XXX This must be fixed: -1 shouldn't be hardcoded (it is the public)
      select decode(count(*),0,'f','t') into exists_p
        from <a class="xref" href="permissions-tediously-explained">acs_object_party_privilege_map</a>
       where object_id = permission_p.object_id
         and party_id in (permission_p.party_id, -1)
         and privilege = permission_p.privilege;
      return exists_p;
    end;

  end acs_permission;
    
</pre><p><span class="strong"><strong>problem
avoidance</strong></span></p><p>The function queries <a class="xref" href="permissions-tediously-explained">
acs_object_party_privilege_map</a>, which is a humongous view that
joins three flattened hierarchies: the context tree, the privilege
hierarchy, the party composition (and membership) hierarchy. It
contains an extremely large number of rows. About the only kind of
query you can run against it is the one performed by the
<code class="computeroutput">acs_permission.permission_p</code>
function. Anything other than that would take forever to finish or
would ultimately result in a query error.</p><p>For example, do not try to do things like</p><pre class="programlisting">
select count(*)
  from <a class="xref" href="permissions-tediously-explained">acs_object_party_privilege_map</a>;
    
</pre><p>To give another example of things to avoid, I have seen code
like this:</p><pre class="programlisting">
  declare
      cursor cur is
        select
           object_id, party_id
        from
           <a class="xref" href="permissions-tediously-explained">acs_object_party_privilege_map</a>
        where
           privilege = 'foo_create';
  begin
      -- revoke all 'foo_create' permissions
      for rec in cur
      loop
          acs_permission.revoke_permission (
              object_id  =<span class="markup">&gt;</span> rec.object_id,
              grantee_id =<span class="markup">&gt;</span> rec.party_id,
              privilege  =<span class="markup">&gt;</span> 'foo_create'
          );
      end loop;

      acs_privilege.remove_child('admin','foo_create');
      acs_privilege.drop_privilege('foo');

  end;
  /
    
</pre><p>The <code class="computeroutput">acs_permission.revoke_permission</code> function
merely runs a delete statement like so:</p><pre class="programlisting">
  
  delete from
     acs_permissions
  where
     object_id = revoke_permission.object_id
     and grantee_id = revoke_permission.grantee_id
     and privilege = revoke_permission.privilege;
    
</pre><p>Note that in the above example, <code class="computeroutput">acs_permissions</code> had only one entry that
needed to be deleted:</p><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col align="center" class="c1"><col align="center" class="c2"><col align="center" class="c3">
</colgroup><thead><tr>
<th align="center"><code class="computeroutput">object_id</code></th><th align="center"><code class="computeroutput">grantee_id</code></th><th align="center"><code class="computeroutput">privilege</code></th>
</tr></thead><tbody><tr>
<td align="center">default_context</td><td align="center">registered_users</td><td align="center">foo_create</td>
</tr></tbody>
</table></div><p>The above script would never get around to deleting this entry
because it had to loop through a gazillion rows in the humongous
<code class="computeroutput">acs_object_party_privilege_map</code>
view.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-tedious-appendix" id="permissions-tedious-appendix"></a>Appendix: Various View
Definitions</h3></div></div></div><a name="acs_object_party_privilege_map" id="acs_object_party_privilege_map"></a><pre class="programlisting">
create or replace view <span class="bold"><strong>acs_object_party_privilege_map</strong></span>
as
select
  ogpm.object_id,
  gmm.member_id as party_id,
  ogpm.privilege
from
  <a class="xref" href="permissions-tediously-explained">acs_object_grantee_priv_map</a> ogpm,
  <a class="xref" href="permissions-tediously-explained">group_member_map</a> gmm
where
  ogpm.grantee_id = gmm.group_id
union
select
  object_id,
  grantee_id as party_id,
  privilege
from
  <a class="xref" href="permissions-tediously-explained">acs_object_grantee_priv_map</a>;
    
</pre><a name="acs_object_grantee_priv_map" id="acs_object_grantee_priv_map"></a><pre class="programlisting">
create or replace view <span class="bold"><strong>acs_object_grantee_priv_map</strong></span>
as
select
  a.object_id,
  a.grantee_id,
  m.descendant as privilege
from
  <a class="xref" href="permissions-tediously-explained">acs_permission_all</a> a,
  <a class="xref" href="permissions-tediously-explained">acs_privilege_descendant_map</a> m
where
  a.privilege = m.privilege;
    
</pre><a name="acs_permissions_all" id="acs_permissions_all"></a><pre class="programlisting">
 
create or replace view <span class="bold"><strong>acs_permissions_all</strong></span>
as
select
  op.object_id,
  p.grantee_id,
  p.privilege
from
  <a class="xref" href="permissions-tediously-explained">acs_object_paths</a> op,
  <a class="xref" href="permissions-tediously-explained">acs_permissions</a> p
where
  op.ancestor_id = p.object_id;
    
</pre><a name="acs_object_paths" id="acs_object_paths"></a><pre class="programlisting">
create or replace view <span class="bold"><strong>acs_object_paths</strong></span>
as
select
  object_id,
  ancestor_id,
  n_generations
from
  <a class="xref" href="permissions-tediously-explained">acs_object_context_index</a>;
    
</pre><a name="group_member_map" id="group_member_map"></a><pre class="programlisting">
 

create or replace view <span class="bold"><strong>group_member_map</strong></span>
as
select
  group_id,
  member_id,
  rel_id,
  container_id
from
  <a class="xref" href="permissions-tediously-explained">group_member_index</a>;
    
</pre>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="parties" leftLabel="Prev" leftTitle="Parties in OpenACS"
		    rightLink="object-identity" rightLabel="Next" rightTitle="Object Identity"
		    homeLink="index" homeLabel="Home" 
		    upLink="dev-guide" upLabel="Up"> 
		