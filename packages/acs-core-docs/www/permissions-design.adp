
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Permissions Design}</property>
<property name="doc(title)">Permissions Design</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="permissions-requirements" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="groups-requirements" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="permissions-design" id="permissions-design"></a>Permissions Design</h2></div></div></div><div class="authorblurb">
<p>By John Prevost and <a class="ulink" href="http://planitia.org" target="_top">Rafael H. Schloming</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-essentials" id="permissions-design-essentials"></a>Essentials</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Tcl in <code class="computeroutput">packages/acs-kernel</code>
</p></li><li class="listitem"><p><a class="xref" href="permissions-requirements" title="Permissions Requirements">OpenACS 4 Permissions
Requirements</a></p></li><li class="listitem"><p><a class="ulink" href="/doc/sql/display-sql?url=acs-permissions-create.sql&amp;package_key=acs-kernel" target="_top">SQL file</a></p></li><li class="listitem"><p><a class="ulink" href="images/permissions-er.png" target="_top">ER diagram</a></p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-intro" id="permissions-design-intro"></a>Introduction</h3></div></div></div><p>The goal of the Permissions system is to provide generic means
to both programmers and site administrators to designate operations
(methods) as requiring permissions, and then to check, grant, or
revoke permissions via a consistent interface. For example, we
might decide that the transaction that bans a user from a sub-site
is an operation a site administrator is able to assign to a
particular user. Or perhaps an application developer might decide
that viewing a certain set of pages within the application is an
operation to be individually granted or revoked from a user.
It&#39;s expected that the Permissions system will be seeing a lot
of use - almost every page will make at least one permissions API
call, and some will make several.</p><p>For programmers, the Permissions API provides a means to work
with access control in a consistent manner. If a programmer&#39;s
OpenACS package defines new methods for itself, the Permissions API
must provide simple calls to determine whether the current user is
authorized to perform the given method. In addition, using the
Permissions API, queries should easily select only those package
objects on which a user has certain permissions.</p><p>For site administrators and other authorized users, the
Permissions UI provides a means to aggregate the primitive
operations (methods) made available by the programmer into logical
privileges (like read, write, and admin) that can be granted and
revoked.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-history" id="permissions-design-history"></a>Historical Considerations</h3></div></div></div><p>In earlier versions of the OpenACS, permissions and access
control was handled on a module-by-module basis, often even on a
page-by-page basis. For example, a typical module might allow any
registered user to access its pages read-only, but only allow
members of a certain group to make changes. The way this group was
determined also varied greatly between modules. Some modules used
"roles", while others did not. Other modules did all
access control based simply on coded rules regarding who can act on
a given database row based on the information in that row.</p><p>Problems resulting from this piecemeal approach to permissions
and access control were many, the two major ones being
inconsistency, and repeated/redundant code. Thus the drive in
OpenACS 4 to provide a unified, consistent permissions system that
both programmers and administrators can readily use.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-competitors" id="permissions-design-competitors"></a>Competitive Analysis</h3></div></div></div><p><span class="emphasis"><em>None available as of
10/2000.</em></span></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-design-tradeoffs" id="permissions-design-design-tradeoffs"></a>Design Tradeoffs</h3></div></div></div><p>The core of the permissions data model is quite simple.
Unfortunately, the hierarchical nature of default permissions
entails quite a number of tree queries which could slow the system
down. Since every page will have at least one permissions check, a
number of views and auxiliary tables (de-normalizations of the data
model) have been created to speed up access queries. As a
consequence, speed of updates are decreased and requirements for
additional storage space increase.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-data-model" id="permissions-design-data-model"></a>Data Model Discussion</h3></div></div></div><p>As described in section V., the core of the permissions data
model is simple, though a number of views and auxiliary tables
exist to ensure adequate performance. The core model consists of
five tables:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><code class="computeroutput">acs_methods</code></span></dt><dd><p>The set of all defined methods.</p></dd><dt><span class="term"><code class="computeroutput">acs_privileges</code></span></dt><dd><p>The set of all defined privileges.</p></dd><dt><span class="term"><code class="computeroutput">acs_privilege_method_rules</code></span></dt><dd><p>A relation describing the set of methods <span class="strong"><strong>directly</strong></span> associated with each
privilege.</p></dd><dt><span class="term"><code class="computeroutput">acs_privilege_hierarchy</code></span></dt><dd><p>A relation describing which privileges <span class="strong"><strong>directly</strong></span> "contain" other
privileges.</p></dd><dt><span class="term"><code class="computeroutput">acs_permissions</code></span></dt><dd><p>A table with one (<span class="emphasis"><em>party</em></span>,
<span class="emphasis"><em>object</em></span>, <span class="emphasis"><em>privilege</em></span>) row for every privilege
<span class="strong"><strong>directly</strong></span> granted on
any object in the system - this is a denormalization of
<code class="computeroutput">acs_privilege_method_rules</code> and
<code class="computeroutput">acs_privilege_hierarchy</code>
</p></dd>
</dl></div><p>There are also a number of views to make it easier to ask
specific questions about permissions. For example, a number of the
above tables describe "direct" or explicit permissions.
Inheritance and default values can, however, introduce permissions
which are not directly specified. (For example, read access on a
forum allows read access on all the messages in the forum.)</p><p>The following views provide flattened versions of inherited
information:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><code class="computeroutput">acs_privilege_method_map</code></span></dt><dd><p>Map of privileges to the methods they contain either directly or
because of another privilege which is included (at any depth).</p></dd><dt><span class="term"><code class="computeroutput">acs_object_grantee_priv_map</code></span></dt><dd><p>Relation on (<span class="emphasis"><em>object</em></span>,
<span class="emphasis"><em>party</em></span>, <span class="emphasis"><em>privilege</em></span>) for privileges from
<code class="computeroutput">acs_privileges</code>) granted
directly on the object, or on the context of the object (at any
depth).</p></dd><dt><span class="term"><code class="computeroutput">acs_object_party_privilege_map</code></span></dt><dd><p>Relation on (<span class="emphasis"><em>object</em></span>,
<span class="emphasis"><em>party</em></span>, <span class="emphasis"><em>privilege</em></span>) for privileges directly from
<code class="computeroutput">acs_object_grantee_priv_map</code> or
also because a party is a member of a group (at any depth).</p></dd><dt><span class="term"><code class="computeroutput">acs_object_party_method_map</code></span></dt><dd><p>Relation with every (<span class="emphasis"><em>object</em></span>, <span class="emphasis"><em>party</em></span>, <span class="emphasis"><em>method</em></span>) tuple implied by the above
trees.</p></dd>
</dl></div><p>In general, <span class="strong"><strong>only <code class="computeroutput">acs_object_party_method_map</code>
</strong></span>
should be used for queries from other modules. The other views are
intermediate steps in building that query.</p><p>The data model also includes two simple PL/SQL procedures
(<code class="computeroutput">acs_permission.grant_permission</code> and
<code class="computeroutput">acs_permission.revoke_permission</code>) for
granting and revoking a specific privilege for a specific user on a
specific object.</p><p>To sum up, the PL/SQL procedures are meant to be used to grant
or revoke permissions. The five base tables represent the basic
data model of the system, with a set of views provided to convert
them into a format suitable for joining to answer specific
questions. The exact means by which this transformation takes place
should not be depended on, since they may change for efficiency
reasons.</p><p>The transformations done create a set of default permissions, in
which:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>parties get the privileges of any groups they are directly or
indirectly a member of</p></li><li class="listitem"><p>privileges get associated with the methods of any other
privileges they have taken methods from (at any level) (see
<code class="computeroutput">acs_privilege_hierarchy</code>)</p></li><li class="listitem"><p>objects get access control from direct grants, or inherit
permissions from their context (unless the "don&#39;t
inherit" flag is set)</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-transactions" id="permissions-design-transactions"></a>Legal Transactions</h3></div></div></div><p>There are three essential areas in which all transactions in the
permissions system fall:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Modification of methods and privileges</p></li><li class="listitem"><p>Modification of permissions</p></li><li class="listitem"><p>Queries on permissions</p></li>
</ul></div><p>
<span class="strong"><strong>"Modification of methods and
privileges."</strong></span> This refers to actions that
happen mainly at package installation time - a package will create
a number of methods for its own use, then associate them with the
system&#39;s standard privileges, or new privileges which the
package has created. The association step might also happen later,
if the site-wide administrator chooses to change permissions
policy.</p><p>These steps involve directly manipulating the <code class="computeroutput">acs_methods</code>, <code class="computeroutput">acs_privileges</code>, and <code class="computeroutput">acs_privilege_method_rules</code> tables. A web
page for manipulating these features should be limited to site-wide
administrators.</p><p>
<span class="strong"><strong>"Modification of
permissions"</strong></span> - involves fairly common
operations. Users are typically able to administer permissions for
objects they themselves create. The two basic operations here are
"grant" and "revoke". Granting permissions is
done via <code class="computeroutput">acs_permissions.grant_permission</code>, and
revocation via <code class="computeroutput">acs_permissions.revoke_permission</code>. These
directly manipulate the <code class="computeroutput">acs_permissions</code> table.</p><p>Web pages for making these changes are available to all users,
so they should not be in an admin area. In order to grant and
revoke permissions on an object, the user must have the
<code class="computeroutput">administer_privileges</code> method
permission on that object.</p><p>
<span class="strong"><strong>"Queries on
permissions"</strong></span> - by far the most common
operation is querying the permissions database. Several kinds of
questions are commonly asked: First, and most commonly, "Can
this party perform this method on this object?" Two Tcl
functions are provided to answer this - one which returns a
boolean, the other of which results in an error page. These Tcl
functions directly access the <code class="computeroutput">acs_object_party_method_map</code>.</p><p>The second most commonly asked question occurs when a list of
objects is being displayed, often in order to provide appropriate
UI functionality: "For this party, what methods are available
on these objects?" Here, the SQL query needs to filter based
on whether the party/user can perform some operation on the object.
This is done via a join or sub-select against <code class="computeroutput">acs_object_party_method_map</code>, or by calling
the Tcl functions for appropriate methods.</p><p>Finally, when administering the permissions for an object, a web
page needs to know all permissions directly granted on that object.
This is done by querying against <code class="computeroutput">acs_permissions</code>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-api" id="permissions-design-api"></a>API</h3></div></div></div><p>The API to the permissions system consists of a few well-known
tables, plus a pair of PL/SQL procedures and a pair of Tcl
functions.</p><p><span class="strong"><strong>Tables</strong></span></p><p>
<code class="computeroutput">acs_methods</code>, <code class="computeroutput">acs_privileges</code>, and <code class="computeroutput">acs_privilege_method_rules</code> manage the set
of permissions in the system. At installation time, a package will
add to these three tables to introduce new permissions into the
system.</p><p>The main table for queries is <code class="computeroutput">acs_object_party_method_map</code>, which contains
(<span class="emphasis"><em>object</em></span>, <span class="emphasis"><em>party</em></span>, <span class="emphasis"><em>method</em></span>) triples for all allowed
operations in the system.</p><p>Also of interest for queries is <code class="computeroutput">acs_permissions</code>, which lists directly
granted privileges. Neither <code class="computeroutput">acs_object_party_method_map</code> (which is a
view) nor <code class="computeroutput">acs_permissions</code>
should be updated directly.</p><p><span class="strong"><strong>PL/SQL
Procedures</strong></span></p><p>
<code class="computeroutput">acs_permissions.grant_permission</code> introduces
new permissions for an object. It should be given an (<span class="emphasis"><em>object</em></span>, <span class="emphasis"><em>party</em></span>, <span class="emphasis"><em>privilege</em></span>) triple, and will always
succeed. If the permission is already in the system, no change
occurs. The interface for this procedure is:</p><pre class="programlisting">
procedure grant_permission (
  object_id    acs_permissions.object_id%TYPE,
  grantee_id   acs_permissions.grantee_id%TYPE,
  privilege    acs_permissions.privilege%TYPE
);
</pre><p>
<code class="computeroutput">acs_permissions.revoke_permission</code> removes a
permission entry given a triple. It always succeeds--if a
permission does not exist, nothing changes. The interface for this
procedure is:</p><pre class="programlisting">
procedure revoke_permission (
  object_id    acs_permissions.object_id%TYPE,
  grantee_id   acs_permissions.grantee_id%TYPE,
  privilege    acs_permissions.privilege%TYPE
);
</pre><p>These procedures are defined in <a class="ulink" href="/doc/sql/display-sql?url=acs-permissions-create.sql&amp;package_key=acs-kernel" target="_top"><code class="computeroutput">permissions-create.sql</code></a>
</p><p><span class="strong"><strong>Tcl Procedures</strong></span></p><p>Two Tcl procedures provide a simple call for the query,
"Can this user perform this method on this object?" One
returns true or false, the other presents an error page.</p><p>To receive a true or false value, Tcl code should call:</p><pre class="programlisting">
permission::permission_p -object_id $object_id -party_id $user_id -privilege $method
</pre><p>If the <code class="computeroutput">user_id</code> argument is
left out, then the currently logged in user is checked. To create
an error page, Tcl code should call:</p><pre class="programlisting">
permission::require_permission -object_id $object_id -privilege $method
</pre><p>These procedures are defined in <code class="computeroutput">acs-permissions-procs.tcl</code>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-ui" id="permissions-design-ui"></a>User Interface</h3></div></div></div><p>All users of the permissions system are the same at the
user-interface level. If you have the <code class="computeroutput">administer_privileges</code> method permission on
an object, then you may edit privileges for that object with the
UI.</p><p>The UI currently provides a list of all granted permissions on
the object. If the user wishes to revoke privileges, she may select
a set of grants, choose revoke, confirm their deletion, and be
returned to the same page after those privileges have been
revoked.</p><p>Granting permissions currently (as of 10/2000) works by
providing a list of all possible permissions and a list of all
parties in the system. (For large sites, some future search
mechanism will be necessary.) After choosing privileges to grant,
the user is returned to the "edit privileges for one
object" screen.</p><p>If it makes sense, the system will also display a checkbox which
the user may select to toggle whether permissions are inherited
from the object&#39;s context.</p><p>There are a number of potential future enhancements for the
permissions UI, outlined below.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-configure" id="permissions-design-configure"></a>Configuration/Parameters</h3></div></div></div><p>There are no configuration options for the permissions
system.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-future" id="permissions-design-future"></a>Future Improvements/Areas of Likely
Change</h3></div></div></div><p>The most important future changes to the Permissions system are
likely to be in the UI:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>There should be a page displaying a list of all objects for
which the current user is allowed to administer privileges.</p></li><li class="listitem"><p>Users should be able to view the permissions on any object, or
perhaps on objects which they have the "read_permissions"
method. This would allow them to see what grants are affecting
their objects through inheritance.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-authors" id="permissions-design-authors"></a>Authors</h3></div></div></div><div class="variablelist"><dl class="variablelist">
<dt><span class="term">System creator</span></dt><dd><p><a class="ulink" href="mailto:rhs\@mit.edu" target="_top">Rafael
H. Schloming</a></p></dd><dt><span class="term">System owner</span></dt><dd><p><a class="ulink" href="mailto:rhs\@mit.edu" target="_top">Rafael
H. Schloming</a></p></dd><dt><span class="term">Documentation author</span></dt><dd><p>John Prevost</p></dd>
</dl></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-design-rev-history" id="permissions-design-rev-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>Document Revision
#</strong></span></td><td><span class="strong"><strong>Action Taken,
Notes</strong></span></td><td><span class="strong"><strong>When?</strong></span></td><td><span class="strong"><strong>By Whom?</strong></span></td>
</tr><tr>
<td>0.1</td><td>Creation</td><td>9/11/2000</td><td>John Prevost</td>
</tr><tr>
<td>0.2</td><td>Edited for ACS 4 Beta release</td><td>10/04/2000</td><td>Kai Wu</td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="permissions-requirements" leftLabel="Prev" leftTitle="Permissions Requirements"
		    rightLink="groups-requirements" rightLabel="Next" rightTitle="Groups Requirements"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		