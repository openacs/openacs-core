
<property name="context">{/doc/acs-subsite {Subsite}} {Group Admin Pages - Requirements}</property>
<property name="doc(title)">Group Admin Pages - Requirements</property>
<master>
<h2><font><font>Group Admin Pages - Requirements</font></font></h2>
<font>
<a href="">ACS subsite docs</a> : Group Admin Pages -
Requirements</font>
<h3><font>I. Introduction</font></h3>
<font>The subsites package offers a powerful way to create discrete
collections of subcommunities on top of a single ACS installation.
The package must be permissions-aware for all groups, relational
segments and constraints, and relations.</font>
<p><font>The subsites package must also allow administrators to
dynamically extend existing group and relationship types and to
define attributes for new types.</font></p>
<h3><font>II. Vision Statement</font></h3>
<font>From <a href="/doc/subsites-requirements">/doc/subsites-requirements.html</a>:</font>
<blockquote><font>The other piece of the subsite system is a
subsite package that provides subsite admins a "control panel" for
administering their subsite. This is the same package used to
provide all the community core functionality available at the
"main" site which is in fact simply another
subsite.</font></blockquote>
<font>This control panel needs to treat individual groups as
belonging to a single instance of a subsite. However, groups
themselves are not enough. We must allow a subsite to specify its
own types of groups, instances of those types (or of a type from a
parent subsite), and types of relationships between those
groups.</font>
<h3><font>III. Historical Motivations</font></h3>
<font>In the ACS 3.x architecture, many modules, e.g. portals,
intranet, and bboard, created their own group types to manage
different aspects of the module. While it is true that the ACS
Permissioning package will replace the need for group types used
exclusively for controlling permissions, some modules require the
logical grouping of other parties. For these modules, we must
restrict administrative control of their groups to administrators
of the subsite. Without this ability, a user with administrative
privilege of one subsite can administer all other groups in the
system.</font>
<h3><font>IV. Use case and User Scenarios</font></h3>
<font><b>The Intranet Application</b></font>
<p><font>The Intranet application may model employees in many ways.
Without loss of generality, we assume each employee is a "person"
with an "employment relation" to a company. Figure 1 shows an
outline of what the ACS Site Map may look like with several
companies. Note that each company represents one instance of the
intranet application.</font></p>
<center><table border="1" cellspacing="5" cellpadding="5"><tr><td align="center">
<img src="intranet-company-structure.gif" border="0"><br><hr><b>Figure 1: Structure of Multiple Intranets</b>
</td></tr></table></center>
<font>The employment relation is a subtype of the ACS Membership
Relation with additional attributes specific to employees (e.g.
salary, start date, etc.). Administrators of each instance of the
intranet application must be able to create the subtype and to
specify the attributes of the subtype dynamically. For example, the
ArsDigita administrator may track salary, biography, and education
while IBM administrators may choose to track salary and family
member information.</font>
<blockquote><font><font size="-1">Note: The current version of ACS,
4.0.1, does not treat object types as objects. This is a problem
for subsites wishing to support dynamic sub-typing as name
collisions are common because object types do not have context. The
ability to create unique types of relationships for a given
instance of the intranet application requires the object type to be
unique to the instance. In other words, the context of the object
type is set to the subsite. We use the context here so that we can
automatically maintain permissions from subsite to object
type.</font></font></blockquote>
<h3><font>VI.A Requirements: Data Model</font></h3>
<dl>
<dt><font><b>10.10 Default relationship types for group
types</b></font></dt><dd><p><font>Each group type should specify a set of permissible
relationship types to use for groups of that type.</font></p></dd><dt><font><br></font></dt><dt><font><b>10.20 Default relationship types for
groups</b></font></dt><dd><p><font>The administrator must be able to specify the permissible
relationship types to use for each group. The defaults are
inherited from the list of permissible relationship types for the
group's type.</font></p></dd>
</dl>
<h3><font>VI.B Requirements: API</font></h3>
<dl>
<dt><font><b>20.10 Define a new group type</b></font></dt><dd><p><font>Users should be able to create a new type of
group.</font></p></dd><dt><font><b>30.10 Specify attributes</b></font></dt><dd><p><font>Users should be able to dynamically add attributes to
group types. These attributes should be stored
efficiently.</font></p></dd><dt><font><b>35.10 Remove attributes</b></font></dt><dd><p><font>Users should be able to dynamically remove attributes from
a group type. Removing the attribute removes all values specified
for that attribute.</font></p></dd><dt><font><b>40.10 Relationship Constraints</b></font></dt><dd><p><font>The API must support the following types of constraints on
relationships:</font></p></dd><dt><font><b>40.10.10 Permissible relationships</b></font></dt><dd><p><font>Each group type should maintain a list of all relationship
types that can be used to add elements to groups of this group
type.</font></p></dd><dt><font><b>40.10.20 Constraints on relationships</b></font></dt><dd><p><font>Relationships listed as allowable for a given group type
should link to more information about the relationship type,
including any constraints that must be satisfied before relations
of the specified type are created.</font></p></dd><dt><font><b>40.10.30 Constrain membership to a given
group</b></font></dt><dd><p><font>The system provides a well-defined API call that adds a
given relationship type to the list of allowable relationship types
to apply to a given group or group type. Any subtype of an
allowable relationship type will also be allowed.</font></p></dd>
</dl>
<h3><font>VI.C Requirements: User Interface</font></h3>
<dl>
<dt><font>
<b>100.10</b> Create a group type with
attributes</font></dt><dd><p><font>When creating a new group type, the UI should support ACS
datatypes with appropriate UI.</font></p></dd><dt><font>
<b>130.10</b> Group type summary page</font></dt><dd><blockquote><dl>
<dt><font>
<b>130.10.10</b> Display allowable relationship
types</font></dt><dd><p><font>The group type summary page should display all the
relationship types used to add relations to groups of this type and
allow the user to add permissible relationship types or to remove
existing ones.</font></p></dd><dt><font>
<b>130.10.20</b> Display groups</font></dt><dd><p><font>Display all groups of this type, based on permissions. UI
should scale well with a large number of groups.</font></p></dd><dt><font>
<b>110.10</b> Create an instance of a particular group
type</font></dt><dd><p><font>When creating a new group of the specified type, the UI
must request values for each of the attributes of that type,
including attributes of all supertypes (up the type tree until the
object of type 'group').</font></p></dd><dt><font>
<b>130.10.20</b> Display type attributes</font></dt><dd><p><font>Display all attributes for this group type, including
supertypes.</font></p></dd><dt><font>
<b>130.10.20</b> Delete group type</font></dt><dd><p><font>Allow administrators to delete the group type. This action
removes all groups of this type.</font></p></dd>
</dl></blockquote></dd>
</dl>
<dl><dt><font>
<b>150.10</b> Group instance summary page</font></dt></dl>
<blockquote><dl>
<dt><font>
<b>150.10.10</b> Display relations</font></dt><dd><p><font>Each group should display all the parties related to it
and through what relationship type. Offer links to remove each
relation or to add a new relation of a given type. The UI for
relations should scale well.</font></p></dd><dt><font>
<b>150.10.20</b> Display attributes</font></dt><dd><p><font>Display all attributes of the group with links to edit
each.</font></p></dd><dt><font>
<b>150.10.20</b> Delete group</font></dt><dd><p><font>Allow administrators to delete the group including all
relations to the group.</font></p></dd><dt><font>
<b>150.20</b> Integration with relational Segments and
Constraints</font></dt><dd><p><font>The group summary page should offer links to define
relational segments for the group, based on a particular
relationship type. The UI must also integrate with the relational
constraints data model to support defining constraints on
intra-party relations.</font></p></dd>
</dl></blockquote>
<h3><font>Revision History</font></h3>
<table cellpadding="2" cellspacing="2" width="90%" bgcolor="#EFEFEF">
<tr bgcolor="#E0E0E0">
<th width="10%">Document Revision #</th><th width="50%">Action Taken, Notes</th><th>When?</th><th>By Whom?</th>
</tr><tr>
<td>0.1</td><td>Creation</td><td>11/16/2000</td><td>Michael Bryzek</td>
</tr><tr>
<td>0.2</td><td>Major Revisions</td><td>11/24/2000</td><td>Michael Bryzek</td>
</tr><tr>
<td>1.0</td><td>Final Revisions</td><td>1/11/2001</td><td>Michael Bryzek</td>
</tr>
</table>
<hr>
<address><a href="mailto:mbryzek\@arsdigita.com">Michael
Bryzek</a></address>
<br>
<font size="-1">$&zwnj;Id: group-admin-pages-requirements.html,v 1.2
2001/08/11 21:31:03 ben Exp $</font>
