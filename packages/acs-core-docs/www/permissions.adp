
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Groups, Context, Permissions}</property>
<property name="doc(title)">Groups, Context, Permissions</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="templates" leftLabel="Prev"
			title="Chapter 11. Development
Reference"
			rightLink="subsites" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="permissions" id="permissions"></a>Groups, Context, Permissions</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By Pete Su</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-overview" id="permissions-overview"></a>Overview</h3></div></div></div><p>The OpenACS 5.9.0 Permissions system allows developers and
administrators to set access control policies at the object level,
that is, any application or system object represented by a row in
the <code class="computeroutput">acs_objects</code> table can be
access-controlled via a PL/SQL or Tcl interface. The permissions
system manages a data model that then allows scripts to check
permissions using another API call.</p><p>Although object level permissions seems appropriate, no
developer or administrator wants to <span class="emphasis"><em>explicitly</em></span> set access control rights for
<span class="emphasis"><em>every user</em></span> and <span class="emphasis"><em>every object</em></span> on a site. Therefore,
OpenACS has two auxiliary mechanisms for making this easier:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>the Groups system allows users to be grouped together in
flexible ways.</p></li><li class="listitem"><p>the object model defines a notion of <span class="emphasis"><em>object context</em></span>, which allows
applications to group objects together into larger security
domains.</p></li>
</ol></div><p>The rest of this document discusses each of these parts, and how
they fit together with the permissions system.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-groups" id="permissions-groups"></a>Groups</h3></div></div></div><p>OpenACS 5.9.0 has an abstraction called a <span class="emphasis"><em>party</em></span>. Parties have a recursive
definition. We can illustrate how it works with the following
simplified data model. First, we define the <code class="computeroutput">parties</code> table, where each party has an
email address and a URL for contact information.</p><pre class="programlisting">

create table parties (
    party_id  integer not null references acs_objects(object_id),
    email varchar(100),
    url varchar(100)
)

</pre><p>Now we define two subtypes of party, one for persons, and one
for groups:</p><pre class="programlisting">

create table groups (
    group_id  not null references parties(party_id),
    group_name varchar(100) not null
)

create table persons (
    person_id not null references parties(party_id),
    first_names varchar(100) not null,
    last_name varchar(100) not null
)

</pre><p>The <code class="computeroutput">users</code> table is also
defined in this data model as a subtype of <code class="computeroutput">person</code>.</p><p>Finally, we define two relations, one for group <span class="emphasis"><em>membership</em></span> and one for group
<span class="emphasis"><em>composition</em></span>.</p><p>The composition relation expresses that every member of group A
should also be a member of group B. This relation allows us to
define a hierarchy of groups.</p><p>The membership relation maps groups to <span class="emphasis"><em>parties</em></span>. Each member of a group is a
party rather than just a user. That is, groups consist of members
that are either a person or an entire group. This allows us to say
that group A should be a member of another group B.</p><p>The groups data model is recursive. Modelling parties as either
a person or a group provides a way to model complex hierarchical
groupings of persons and groups.</p><p>The full details of the groups data model is beyond the scope of
this tutorial. See <a class="xref" href="parties" title="Parties in OpenACS">Parties in OpenACS</a> or <a class="xref" href="groups-design" title="Groups Design">OpenACS 4 Groups
Design</a> for more details.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-permissions" id="permissions-permissions"></a>Permissions</h3></div></div></div><p>NOTE: Much more detailed information about the permissions
system and how to use it is available in the <a class="xref" href="permissions-tediously-explained" title="OpenACS Permissions Tediously Explained">OpenACS Permissions
Tediously Explained</a> document.</p><p>The permissions data model is a mapping between <span class="emphasis"><em>privileges</em></span>, parties and objects. Parties
and objects have already been discussed. Now we focus on
privileges.</p><p>In OpenACS, a privilege describes the right to perform some
operation on some object. Privileges are the basic units out of
which we build access control policies. For example in the Unix
filesystem, access is controlled by granting users some combination
of read, write, or execute privileges on files and directories. In
OpenACS 5.9.0, the table of privileges is organized hierarchically
so that developers can define privileges that aggregate some set of
privileges together. For example, if we have read, write, create
and delete privileges, it might be convenient to combine them into
a new privilege called "admin". Then, when a user is
granted "admin" privilege, she is automatically granted
all the child privileges that the privilege contains. The OpenACS
5.9.0 kernel data model defines these privileges:</p><pre class="programlisting">
# 
begin
 acs_privilege.create_privilege('read');
 acs_privilege.create_privilege('write');
 acs_privilege.create_privilege('create');
 acs_privilege.create_privilege('delete');
 acs_privilege.create_privilege('admin');

 acs_privilege.add_child('admin', 'read');
 acs_privilege.add_child('admin', 'write');
 acs_privilege.add_child('admin', 'create');
 acs_privilege.add_child('admin', 'delete');

 commit;
end;

</pre><p>Note that a user does not gain admin privileges when granted
read, write, create and delete privileges, because some operations
explicitly require admin privileges. No substitutions.</p><p>To give a user permission to perform a particular operation on a
particular object you call <code class="computeroutput">acs_permission.grant_permission</code> like
this:</p><pre class="programlisting">
# sql code
    acs_permission.grant_permission (
      object_id =&gt; some_object_id,
      grantee_id =&gt; some_party_id,
      privilege =&gt; 'some_privilege_name'
      );

</pre><p>Using just these mechanisms is enough for developers and
administrators to effectively define access control for every
object in a system.</p><p>Explicitly defining permissions to every object individually
would become very tedious. OpenACS provides a object contexts as a
means for controlling permissions of a large group of objects at
the same time.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-object-context" id="permissions-object-context"></a>Object Context</h3></div></div></div><p>In OpenACS 5.9.0, object context is a scoping mechanism.
"Scoping" and "scope" are terms best explained
by example: consider some hypothetical rows in the <code class="computeroutput">address_book</code> table:</p><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col><col>
</colgroup><thead><tr>
<th>...</th><th><code class="computeroutput">scope</code></th><th><code class="computeroutput">user_id</code></th><th><code class="computeroutput">group_id</code></th><th>...</th>
</tr></thead><tbody>
<tr>
<td>...</td><td><code class="computeroutput">user</code></td><td><code class="computeroutput">123</code></td><td></td><td>...</td>
</tr><tr>
<td>...</td><td><code class="computeroutput">group</code></td><td></td><td><code class="computeroutput">456</code></td><td>...</td>
</tr><tr>
<td>...</td><td><code class="computeroutput">public</code></td><td></td><td></td><td>...</td>
</tr>
</tbody>
</table></div><p>The first row represents an entry in User 123's personal
address book, the second row represents an entry in User Group
456's shared address book, and the third row represents an
entry in the site&#39;s public address book. In this way, the
scoping columns identify the security context in which a given
object belongs, where each context is <span class="emphasis"><em>either</em></span> a person <span class="emphasis"><em>or</em></span> a group of people <span class="emphasis"><em>or</em></span> the general public (itself a group of
people).</p><p>Every object lives in a single <span class="emphasis"><em>context</em></span>. A context is just an another
object that represents the security domain to which the object
belongs. By convention, if an object A does not have any
permissions explicitly attached to it, then the system will look at
the <code class="computeroutput">context_id</code> column in
<code class="computeroutput">acs_objects</code> and check the
context object there for permissions. Two things control the scope
of this search:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>the structure of the context hierarchy itself, and</p></li><li class="listitem"><p>the value of the <code class="computeroutput">security_inherit_p</code> flag in each object.</p></li>
</ol></div><p>If <code class="computeroutput">security_inherit_p</code> flag
is set to <code class="computeroutput">'t'</code>, then the
automatic search through the context happens, otherwise it does
not. You might set this field to <code class="computeroutput">'f'</code> if you want to override the
default permissions in a subtree of some context.</p><p>For an example of how to use context hierarchy, consider the
forums application. With only row-level permissions it is not
obvious how to reasonably initialize the access control list when
creating a message. At best, we have to explicitly grant various
read and write privileges whenever we create a message, which is
tedious. A reasonable thing to do is to create an object
representing a forum, and point the <code class="computeroutput">context_id</code> field of a new message at the
forum. Then, suppose we grant every user in the system read-access
to this forum. By default, they will automatically have read-access
to the new message we just inserted, since the system automatically
checks permissions on the message&#39;s context. To allow the
creator of the message to change the message after it has been
posted we grant the user write-access on the message, and we are
done.</p><p>This mechanism allows developers and administrators to define a
hierarchy that matches the structure they need for access control
in their application. The following picture shows a typical context
hierarchy for a hypothetical site:</p><div class="blockquote"><blockquote class="blockquote"><div><img src="images/context-hierarchy.gif"></div></blockquote></div><p>The top two contexts in the diagram are called "magic"
numbers, because in some sense, they are created by default by
OpenACS for a specific purpose. The object <code class="computeroutput">default_context</code> represents the root of the
context hierarchy for the entire site. All permission searches walk
up the tree to this point and then stop. If you grant permissions
on this object, then by default those permissions will hold for
every object in the system, regardless of which subsite they happen
to live in. The object <code class="computeroutput">security_context_root</code> has a slightly
different role. If some object has no permissions attached to it,
and its value for <code class="computeroutput">security_inherit_p</code> is <code class="computeroutput">'f'</code>, or <code class="computeroutput">context_id</code> is null, this context is used by
default.</p><p>See the package developer tutorials for examples on how to use
permissions code.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-summary" id="permissions-summary"></a>Summary</h3></div></div></div><p>OpenACS 5.9.0 defines three separate mechanisms for specifying
access control in applications.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>The Groups data model allows you to define hierarchical
organizations of users and groups of users.</p></li><li class="listitem"><p>The Permissions data model allows you to define a hierarchy of
user rights.</p></li><li class="listitem"><p>The Context hierarchy allows you to define organize default
permissions in a hierarchical fashion.</p></li>
</ol></div><p>A PL/SQL or Tcl API is then used to check permissions in
application pages.</p><p><span class="cvstag">($&zwnj;Id: permissions.xml,v 1.18 2017/08/07
23:47:54 gustafn Exp $)</span></p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="templates" leftLabel="Prev" leftTitle="Using Templates in OpenACS"
			rightLink="subsites" rightLabel="Next" rightTitle="Writing OpenACS Application
Pages"
			homeLink="index" homeLabel="Home" 
			upLink="dev-guide" upLabel="Up"> 
		    