
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Permissions Requirements}</property>
<property name="doc(title)">Permissions Requirements</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="object-system-design" leftLabel="Prev"
			title="Chapter 15. Kernel
Documentation"
			rightLink="permissions-design" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="permissions-requirements" id="permissions-requirements"></a>Permissions Requirements</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By John McClary Prevost</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-requirements-intro" id="permissions-requirements-intro"></a>Introduction</h3></div></div></div><p>This document records requirements for the OpenACS 4 Permissions
system, a component of the OpenACS 4 Kernel. The Permissions system
is meant to unify and centralize the handling of access and control
on a given OpenACS 4 system.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-requirements-vision" id="permissions-requirements-vision"></a>Vision Statement</h3></div></div></div><p>Any multi-user software system must address the general problem
of permissions, or "who can do what, on what." On web
services, which typically involve large numbers of users belonging
to different groups, permissions handling is a critical need:
access to content, services, and information generally must be
controlled. The OpenACS 4 Permissions system is meant to serve as a
consistent, unified interface for higher-level OpenACS applications
to handle permissions. Consolidating access control in such a
manner reduces both cost and risk: cost, in that less code has to
be written and maintained for dealing with recurring permissions
situations; risk, in that we need not rely on any single
programmer&#39;s diligence to ensure access control is implemented
and enforced correctly.</p><p><span class="strong"><strong>Historical
Motivations</strong></span></p><p>In earlier versions of the OpenACS, permissions and access
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
<a name="permissions-requirements-system-overview" id="permissions-requirements-system-overview"></a>System Overview</h3></div></div></div><p>The OpenACS 4 Permissions system has two main pieces: first, an
API for developers to readily handle access control in their
applications. The second piece of the system is a UI meant
primarily for (subsite) administrators to grant and revoke
permissions to system entities under their control.</p><p>Consistency is a key characteristic of the Permissions system -
both for a common administrative interface, and easily deployed and
maintained access control. The system must be flexible enough to
support every access model required in OpenACS applications, but
not so flexible that pieces will go unused or fall outside the
common administrative interfaces.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-requirements-" id="permissions-requirements-"></a>Use Cases and User Scenarios</h3></div></div></div><p><span class="strong"><strong>Terminology</strong></span></p><p>The primary question an access control system must answer is a
three-way relation, like that between the parts of most simple
sentences. A simple sentence generally has three parts, a subject,
an object, and a verb - in the context of OpenACS Permissions, our
simple sentence is, "Can this party perform this operation on
this target?" Definitions:</p><p>The subject of the sentence is "<span class="strong"><strong>party</strong></span>" - a distinguishable
actor whose access may be controlled, this special word is used
because one person may be represented by several parties, and one
party may represent many users (or no users at all).</p><p>The object of the sentence is "<span class="strong"><strong>target</strong></span>" - this is an entity,
or object, that the party wishes to perform some action on. An
entity/object here is anything that can be put under access
control.</p><p>The verb of the sentence is "operation" - a behavior
on the OpenACS system subject to control, this word is used to
represent the fact that a single operation may be part of many
larger actions the system wants to perform. If "foo" is
an operation, than we sometimes refer to the foo
"privilege" to mean that a user has the privilege to
perform that operation.</p><p>Examples of the essential question addressed by the Permissions
system: Can jane\@attacker.com delete the web security forum? Can
the Boston office (a party) within the VirtuaCorp intranet/website
create its own news instance?</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-requirements-links" id="permissions-requirements-links"></a>Related Links</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p><a class="xref" href="permissions-design" title="Permissions Design">OpenACS 4 Permissions Design</a></p></li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-requirements-func-req" id="permissions-requirements-func-req"></a>Functional
Requirements</h3></div></div></div><p><span class="strong"><strong>10.0
Granularity</strong></span></p><p>The system must support access control down to the level of a
single entity (this would imply down to the level of a row in the
OpenACS Objects data model).</p><p><span class="strong"><strong>20.0 Operations</strong></span></p><p>The system itself must be able to answer the essential
permissions question as well as several derived questions.</p><div class="blockquote"><blockquote class="blockquote">
<p><span class="strong"><strong>20.10 Basic Access
Check</strong></span></p><p>The system must be able to answer the question, "May party
P perform operation O on target T?"</p>
</blockquote></div><div class="blockquote"><blockquote class="blockquote">
<p><span class="strong"><strong>20.20 Allowed Parties
Check</strong></span></p><p>The system must be able to answer the question, "Which
parties may perform operation O on target T?"</p>
</blockquote></div><div class="blockquote"><blockquote class="blockquote">
<p><span class="strong"><strong>20.30 Allowed Operations
Check</strong></span></p><p>The system must be able to answer the question, "Which
operations may party P perform on target T?"</p>
</blockquote></div><div class="blockquote"><blockquote class="blockquote">
<p><span class="strong"><strong>20.40 Allowed Targets
Check</strong></span></p><p>The system must be able to answer the question, "Upon which
targets may party P perform operation O?"</p>
</blockquote></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-requirements-behave-req" id="permissions-requirements-behave-req"></a>Behavioral
Requirements</h3></div></div></div><p><span class="strong"><strong>40.0 Scale of
Privileges</strong></span></p><p>Privileges must be designed with appropriate scope for a given
OpenACS package. Some privileges are of general utility (e.g.
"read" and "write"). Others are of more limited
use (e.g. "moderate" - applies mainly to a package like
forum, where many users are contributing content simultaneously). A
package defining its own privileges should do so with moderation,
being careful not to overload a privilege like "read" to
mean too many things.</p><p><span class="strong"><strong>50.0 Aggregation of Operations
(Privileges)</strong></span></p><p>For user interface purposes, it can be appropriate to group
certain privileges under others. For example, anyone with the
"admin" privilege may also automatically receive
"read", "write", "delete", etc.
privileges.</p><p><span class="strong"><strong>60.0 Aggregation of Parties
(Groups)</strong></span></p><p>The system must allow aggregation of parties. The exact method
used for aggregation will probably be addressed by the OpenACS 4
"Groups" system. Regardless of the exact behavior of
aggregate parties, if an aggregate party exists, then access which
is granted to the aggregate party should be available to all
members of that aggregate.</p><p><span class="strong"><strong>70.0 Scope of Access
Control</strong></span></p><div class="blockquote"><blockquote class="blockquote">
<p><span class="strong"><strong>70.10 Context</strong></span></p><p>There must be a method for objects to receive default access
control from some context. For example, if you do not have read
access to a forum, you should not have read access to a message in
that forum.</p>
</blockquote></div><div class="blockquote"><blockquote class="blockquote">
<p><span class="strong"><strong>70.20
Overriding</strong></span></p><p>It must be possible to override defaults provided by the context
of an object (as in 70.10), in both a positive and negative
manner.</p>
</blockquote></div><div class="blockquote"><blockquote class="blockquote">
<p><span class="strong"><strong>70.20.10 Positive
Overriding</strong></span></p><p>It must be possible to allow a party more access to some target
than they would get by default. (For example, a user does not have
the right to edit any message on a forum. But a user does possibly
have the right to edit their own messages.)</p>
</blockquote></div><div class="blockquote"><blockquote class="blockquote">
<p><span class="strong"><strong>70.20.20 Negative
Overriding</strong></span></p><p>It must be possible to deny a party access to some target that
their inherited privileges would have allowed. (For example, a
subdirectory in the file-storage might normally have its parent
directory as context. It should be possible, however, to make a
subdirectory private to some group.)</p>
</blockquote></div><p><span class="strong"><strong>100.0
Efficiency</strong></span></p><p>At least the basic access check (20.10) and the allowed targets
check (20.40) must be efficient enough for general use, i.e.
scalable under fairly heavy website traffic. It can be expected
that almost every page will contain at least one basic access
check, and most pages will contain an allowed targets check
(20.40).</p><p>In particular, constraining a <code class="computeroutput">SELECT</code> to return only rows the current user
has access to should not be much slower than the <code class="computeroutput">SELECT</code> on its own.</p><p><span class="strong"><strong>120.0 Ease of
Use</strong></span></p><p>Since most SQL queries will contain an allowed target check in
the where clause, whatever mechanism is used to make checks in SQL
should be fairly small and simple.</p><p>In particular, constraining a <code class="computeroutput">SELECT</code> to return only rows the current user
has access to should not add more than one line to a query.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="permissions-requirements-history" id="permissions-requirements-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>Document Revision
#</strong></span></td><td><span class="strong"><strong>Action Taken,
Notes</strong></span></td><td><span class="strong"><strong>When?</strong></span></td><td><span class="strong"><strong>By Whom?</strong></span></td>
</tr><tr>
<td>0.1</td><td>Creation</td><td>8/17/2000</td><td>John Prevost</td>
</tr><tr>
<td>0.2</td><td>Revised, updated with new terminology</td><td>8/25/2000</td><td>John Prevost</td>
</tr><tr>
<td>0.3</td><td>Edited, reformatted to conform to requirements template,
pending freeze.</td><td>8/26/2000</td><td>Kai Wu</td>
</tr><tr>
<td>0.4</td><td>Edited for ACS 4 Beta release.</td><td>10/03/2000</td><td>Kai Wu</td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="object-system-design" leftLabel="Prev" leftTitle="Object Model Design"
			rightLink="permissions-design" rightLabel="Next" rightTitle="Permissions Design"
			homeLink="index" homeLabel="Home" 
			upLink="kernel-doc" upLabel="Up"> 
		    