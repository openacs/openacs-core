
<property name="context">{/doc/acs-subsite {ACS Subsite}} {Group Admin Pages - Design}</property>
<property name="doc(title)">Group Admin Pages - Design</property>
<master>
<h2>Group Admin Pages - Design</h2>
<a href="">ACS subsite docs</a>
 : Group Admin Pages - Design
<h3>I. Essentials</h3>
<ul>
<li>ACS administrator directory (/admin/groups for each
subsite)</li><li><a href="/api-doc/">Tcl script directory</a></li><li><a href="/api-doc/plsql-subprograms-all">PL/SQL
packages</a></li><li><a href="group-admin-pages-requirements">Requirements
document</a></li><li><a href="group-admin-pages-acceptance-test">Acceptance
test</a></li>
</ul>
<h3>II. Introduction</h3>

The group administration packages provides a "control
panel" to allow the administrator of a subsite to control the
groups in use on that subsite. Administrators manage the types of
groups in use on a subsite. For each of these group types, the
administrator can create new groups, specify applicable
relationship types, create relations between these groups, and
modify attributes of the types and groups.
<h3>III. Historical Considerations</h3>

Versions 4.0.x of the ACS lacked a useful group administration
package for subsites. For example:
<ul>
<li>Groups were given no context</li><li>Groups could not be deleted</li><li>Group types could not be created</li><li>Relationships were limited to membership and composition, not
including subtypes of these two.</li>
</ul>

This package addresses most of the short-coming of the previous
subsites group administration package making group administration
subsite aware and better integrated with the ACS Object Model.
<h3>IV. Design Tradeoffs</h3>

Whenever possible, the design of this package tries to minimize
disturbance to the core ACS 4.0 data model. Instead, we focus on
adding a more powerful user interface and PL/SQL API to the
existing group admin pages while extending the data model only when
necessary.
<h3>V. API</h3>
<h4>Permissible relationship types</h4>

We defined the following two tables to store the relationship type
used to store the permissible relationship types for group types
and individual groups. Whenever a group is created using the
<code>acs_group.new</code>
 function, the relationship types for the
new group are automatically copied from those allowed for its group
type.
<pre>
create table group_type_rels (
       group_rel_type_id      integer constraint gtr_group_rel_type_id_pk primary key,
       rel_type               not null 
                              constraint gtr_rel_type_fk
                              references acs_rel_types (rel_type)
                              on delete cascade,
       group_type             not null 
                              constraint gtr_group_type_fk
                              references acs_object_types (object_type)
                              on delete cascade,
       constraint gtr_group_rel_types_un unique (group_type, rel_type)
);


create table group_rels (
       group_rel_id           integer constraint group_rels_group_rel_id_pk primary key,
       rel_type               not null 
                              constraint group_rels_rel_type_fk
                              references acs_rel_types (rel_type)
                              on delete cascade,
       group_id               not null 
                              constraint group_rels_group_id_fk
                              references groups (group_id)
                              on delete cascade,
       constraint group_rels_group_rel_type_un unique (group_id, rel_type)
);

</pre>
<h4>Dynamic subtypes of object types</h4>

To allow administrators to create dynamic object types (e.g.
subtypes of the object types <code>group</code>
,
<code>membership_rel</code>
, and <code>composition_rel</code>
), we
provide a Tcl library of procedure that generate PL/SQL packages.
For each dynamically created object type, we:
<ul>
<li>We create the ACS object type</li><li>We create a table to store the attributes for the new type</li><li>We create a PL/SQL package with a new function and delete
procedure</li>
</ul>

Whenever an attribute is added or deleted, a type added or removed,
we regenerate some of the PL/SQL packages, based on the type
hierarchy affected by the change.
<p>Attributes themselves are stored using
<code>type-specific</code> storage. For each new attribute, we
create a column in the table dynamically created for the new object
type.</p>
<p>To support the clean separation between programmer defined
PL/SQL packages and automatically generated packages, we add the
<code>dynamic_p</code> column to the <code>acs_object_types</code>
table.</p>
<pre>
acs_object_types.dynamic_p       char(1) default 'f' 
                                 constraint acs_obj_types_dynamic_p_ck
                                 check (dynamic_p in ('t', 'f'))
</pre>
<p><strong>Note that the <code>dynamic_p</code> is still
experimental and may be removed in a future version of
ACS</strong></p>
<h3>VII. Data Model Discussion</h3>

...
<h3>VIII. User Interface</h3>

The user interface comprises entirely of administrative pages
located in the <code>/admin/</code>
 directory of the subsite
package.
<h3>IX. Configuration/Parameters</h3>

The revised group administration pages require no new package
parameters.
<h3>X. Future Improvements/Areas of Likely Change</h3>

There are many areas for improvement to the user interface,
including tighter integration with the relational segments and
constraints packages. One major improvement would allow individual
subsites to define their own group types and relationship types,
separate from any other subsite. However, since ACS object types
are not themselves objects, it is difficult to properly scope
object types.
<p>We also may add a few additional package parameters
including:</p>
<ul>
<li>"Create Group Types" (Boolean). Determines whether
new group types can be created dynamically.</li><li>"Create Relationship Types" (Boolean). Determines
whether new relationship types can be created dynamically.</li>
</ul>
<h3>XI. Authors</h3>

This document is primarily the result of discussions between Oumi
Mehrotra and Michael Bryzek. Bryan Quinn and Rafi Schloming
provided key insights early in the development process.
<ul>
<li>System creator: <a href="mailto:mbryzek\@arsdigita.com">mbryzek\@arsdigita.com</a>
</li><li>System owner: <a href="mailto:mbryzek\@arsdigita.com">mbryzek\@arsdigita.com</a>
</li><li>Documentation author <a href="mailto:mbryzek\@arsdigita.com">mbryzek\@arsdigita.com</a>
</li>
</ul>
<h3>XII. Revision History</h3>
<table cellspacing="2" cellpadding="2" width="90%" bgcolor="#EFEFEF"><tbody>
<tr bgcolor="#E0E0E0">
<th width="10%">Document Revision #</th><th width="50%">Action Taken, Notes</th><th>When?</th><th>By Whom?</th>
</tr><tr>
<td>0.1</td><td>Creation</td><td>11/30/2000</td><td>Michael Bryzek</td>
</tr><tr>
<td>1.0</td><td>Major Revision</td><td>1/11/2001</td><td>Michael Bryzek</td>
</tr>
</tbody></table>
<hr>
<address><a href="mailto:mbryzek\@arsdigita.com">Michael
Bryzek</a></address>
<br>
<font size="-1">group-admin-pages-design.html,v 1.1.4.1 2001/01/12
22:43:33 mbryzek Exp</font>
