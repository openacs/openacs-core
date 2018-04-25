
<property name="context">{/doc/acs-subsite {ACS Subsite}} {Group Admin Pages - Acceptance test}</property>
<property name="doc(title)">Group Admin Pages - Acceptance test</property>
<master>
<h2><font><font>Group Admin Pages - Acceptance
test</font></font></h2>
<font>
<a href="">ACS subsite docs</a> : Group Admin Pages -
Acceptance test</font>
<h3><font>DEVELOPER DEFINED GROUP TYPES TEST</font></h3>
<font>The first thing we have to test is developer defined group
types working in conjunction with the user defined ones.</font>
<p><font>Create the following object type in SQL*Plus.</font></p>
<pre><font>
begin
 acs_object_type.create_type (
   supertype =&gt; 'group',
   object_type =&gt; 'developer_defined_test_type',
   pretty_name =&gt; 'Developer defined test type',
   pretty_plural =&gt; 'Developer defined test types',
   table_name =&gt; 'developer_defined_test_types',
   id_column =&gt; 'test_group_id',
   package_name =&gt; 'developer_defined_test_type',
   name_method =&gt; 'acs_group.name'
 );
end;
/
show errors;   


create table developer_defined_test_types (
       test_group_id   integer primary key references groups(group_id)
);


create or replace package developer_defined_test_type
as

  function new (
         TEST_GROUP_ID   IN DEVELOPER_DEFINED_TEST_TYPES.TEST_GROUP_ID%TYPE DEFAULT NULL,
         GROUP_NAME      IN GROUPS.GROUP_NAME%TYPE,
         OBJECT_TYPE     IN ACS_OBJECTS.OBJECT_TYPE%TYPE DEFAULT 'developer_defined_test_type'
  ) return DEVELOPER_DEFINED_TEST_TYPES.TEST_GROUP_ID%TYPE;

  procedure delete (
    TEST_GROUP_ID      in DEVELOPER_DEFINED_TEST_TYPES.TEST_GROUP_ID%TYPE
  );

end developer_defined_test_type;
/
show errors

create or replace package body developer_defined_test_type
as

  function new (
         TEST_GROUP_ID   IN DEVELOPER_DEFINED_TEST_TYPES.TEST_GROUP_ID%TYPE DEFAULT NULL,
         GROUP_NAME      IN GROUPS.GROUP_NAME%TYPE,
         OBJECT_TYPE     IN ACS_OBJECTS.OBJECT_TYPE%TYPE DEFAULT 'developer_defined_test_type'
  ) return DEVELOPER_DEFINED_TEST_TYPES.TEST_GROUP_ID%TYPE
  is
    v_TEST_GROUP_ID DEVELOPER_DEFINED_TEST_TYPES.TEST_GROUP_ID%TYPE;
  begin

    v_TEST_GROUP_ID := acs_group.new (
                     group_id         =&gt; new.TEST_GROUP_ID,
                     GROUP_NAME       =&gt; new.GROUP_NAME,
                     OBJECT_TYPE      =&gt; new.OBJECT_TYPE
                   );

    insert into DEVELOPER_DEFINED_TEST_TYPES
    (TEST_GROUP_ID)
    values
    (v_TEST_GROUP_ID);

    return v_TEST_GROUP_ID;

  end new;

  procedure delete (
    TEST_GROUP_ID      in DEVELOPER_DEFINED_TEST_TYPES.TEST_GROUP_ID%TYPE
  )
  is
  begin

    acs_group.del( developer_defined_test_type.delete.TEST_GROUP_ID );

  end delete;

end developer_defined_test_type;
/
show errors

</font></pre>
<ol>
<li><font>Go to /admin/group-types and select "Developer
defined test types"</font></li><li><font>Add a permissible rel type of Membership
Relation</font></li><li><font>Add a group named "Test group"</font></li>
</ol>
<h3><font>GROUP TYPE PAGES BASIC FUNCTIONALITY</font></h3>
<font><strong>(Start at /admin)</strong></font>
<ol>
<li><font>Click on group types</font></li><li><font>Click on Groups</font></li><li><font>Click on "Group name" under "Attributes of
this type of group"</font></li><li><font>Ensure that you see the properties of the attribute and
that you are offered no administrative links</font></li><li><font>Make sure you cannot add attributes or do anything under
administration</font></li><li><font>Make sure you see Composition and Membership Relation as
the default relationship types</font></li><li><font>Add a new group called "Foobar" - Make sure
Foobar appears after adding the group</font></li><li><font>Click on Foobar</font></li><li><font>Click on nuke this group then click no. Ensure group is
not deleted</font></li><li><font>Click on nuke this group then click yes. Group should no
longer show up</font></li><li><font>Recreate the group Foobar</font></li><li><font>Click on foobar, then change the name to
"ArsDigita"</font></li><li><font>Change ArsDigita&#39;s join policy to closed</font></li>
</ol>
<h3><font>DYNAMICALLY EXTENDING GROUPS</font></h3>
<font><strong>(Start at /admin/group-types/)</strong></font>
<ol>
<li><font>Click on "Define a new group type" and create a
new group type called "Project" with type
"project". Ensure that all the fields you see are
required (try submitting without entering in anything).</font></li><li><font>Define another group type, child of group, named
"Test"</font></li><li><font>Define another group type, 'subproject', child of
project. Ensure that the index page correctly displays the
hierarchy.</font></li><li><font>Define a new group type with group type = group. See
error message saying type already exists.</font></li><li><font>Go back to the index page
(/admin/group-types).</font></li><li>
<font>Click on the Test group type. Make sure that:</font><ul>
<li><font>there are no groups</font></li><li><font>Group name attribute is inherited from groups</font></li><li><font>you have a link to add an attribute</font></li><li><font>you see Composition and Membership Relation as the
default relationship types</font></li><li><font>You have a link to change the default join
policy</font></li><li><font>You have a link to delete the group type</font></li>
</ul>
</li><li><font>Click on "Add a permissible relationship type."
Ensure that you are not given a select bar but are offered a link
to "create a new relationship type"</font></li><li><font>Create a group of type test.</font></li><li><font>Delete the test group type (first verify that the cancel
button works)</font></li><li><font>Go to the "project" group type</font></li><li><font>Add a required attribute called "Project type"
of datatype enumeration. Values are "Client"
"Toolkit"</font></li><li><font>Add an optional attribute "Monthly fee" of type
integer and default of "10000"</font></li><li><font>Add a third attribute called test.</font></li><li><font>Make sure you can see all the attributes. Delete the test
attribute</font></li><li>
<font>Go to
"/admin/object-types/one?object_type=project" and ensure
that start_date and monthly fees are listed as attributes. Also
make sure:</font><ul>
<li><font>test attribute is not visible</font></li><li><font>monthly_fee has a default specified (NULL) in the pl/sql
parameter list</font></li><li><font>start_date has no default specified</font></li>
</ul>
</li><li><font>Go to
"/admin/object-types/one?object_type=subproject" and
ensure the new attributes of project are in the pl/sql
package</font></li><li><font>Now go back to the group type admin page for the
"Projects" group type. Remove the composition relation.
Make sure you get a link back to add a relationship type. Add back
the composition relation.</font></li><li><font>Add a group of type project named
GuideStar.org</font></li>
</ol>
<h3><font>RELATIONSHIP TYPE PAGES BASIC FUNCTIONALITY</font></h3>
<ol>
<li><font>Create a new relationship type, Employment relation, that
is a subtype of Membership relation, between group and person.
Group has role of employer, person role of employee.</font></li><li><font>Select the employment relation and add an attribute age
(integer, not required)</font></li><li><font>Delete the employment relationship type.</font></li><li><font>Re-add the employment relationship type (we&#39;re
testing to make sure the age attribute is correctly removed and
flushed from the cache)</font></li><li><font>Click on membership relation, then click on create
subtype</font></li><li><font>Click on membership relation -&gt; Create subtype type:
project_lead_relation name: Project Lead between projects (the
composite) and persons (the project leader new role)</font></li><li><font>Create a new, dummy rel type, subtype of Project Lead
Relation. Make sure the only things in object type one are project
and subproject</font></li><li><font>Select the dummy relationship type and then delete
it.</font></li><li><font>Select the Employment relation and add a required
attribute "salary" (type integer)</font></li>
</ol>
<h3><font>SEGMENTS, CONSTRAINTS AND RELATIONS</font></h3>
<ol>
<li><font>Go back to the admin page (/admin)</font></li><li><font>Click on the Groups -&gt; GuideStar.org. Add ArsDigita as
a component</font></li><li><font>Remove the composition rel type from this
group</font></li><li><font>Readd the composition rel type. Make sure arsdigita
doesn&#39;t show up</font></li><li><font>remove the composition rel type</font></li><li><font>Add a permissible rel type:
project_lead_relation</font></li><li><font>Click yes to create a rel segment named "GuideStar
Project Leads"</font></li><li><font>Go back to /admin/groups</font></li><li><font>Click on "relationship to site"</font></li><li><font>Remove yourself from the group.</font></li><li><font>Add yourself again as a member (using the membership
relation). You will have to select an existing party from the
system.</font></li><li><font>Make sure you see the segment "Main Site
Members" for parties with a membership relation to the main
site.</font></li><li><font>Go to the ArsDigita group.</font></li><li><font>Add guidestar.org as a component</font></li><li><font>Remove the membership relation type from this
group</font></li><li><font>Add the employment relation type</font></li><li><font>Create a segment named "ArsDigita
employees"</font></li><li><font>Add a constraint named "ArsDigita employees must be
Main Site Members" for employees and the segment "Main
Site Members"</font></li><li><font>Go back to the guidestar.org group</font></li><li><font>Add yourself as a project lead.</font></li><li><font>Click on the project lead segment "GuideStar Project
Leads"</font></li><li><font>Click delete this segment. Say no.</font></li><li><font>Click delete this segment. Say Yes.</font></li><li><font>Recreate the "GuideStar Project Leads"
segment</font></li><li><font>Add a constraint named "Project leads must be
employees" that says all "project leaders must be
employees of ArsDigita"</font></li><li><font>Make sure you see yourself as a violation. Remove the
violating relation and finish adding the constraint</font></li><li><font>Try to add a project leader to guidestar. You should see
that there "There is no other Person that can be added as
Project Leader to GuideStar.Org"</font></li><li><font>Add yourself as an arsdigita employee</font></li><li><font>Make yourself the project lead on
guidestar.org</font></li><li><font>Go back to /admin/groups and select "relationship
typ site." Remove your membership relation. You should get
prompted to remove relation to arsdigita, then to guidestar. Remove
all of these relations.</font></li><li><font>Make yourself a project lead of guidestar
again.</font></li>
</ol>
<h3><font>Testing with more Users</font></h3>
<font>Now we&#39;re going to test that the user interface remains
consistent if there are a few more users.</font>
<ol>
<li><font>Go to /acs-admin/users and add 4 users</font></li><li><font>Go to /admin/groups and click on "relationship to
site." You should see all of the people you just entered
listed as members of the subsite.</font></li><li><font>Try to remove your Membership relation. You should see
only one constraint violation.</font></li><li><font>Remove one of the other people from the registered users
group. You should be allowed to do it immediately.</font></li><li><font>Add back the person you removed.</font></li><li><font>Remove yourself from the registered users group. Make
yourself a project lead on guidestar again.</font></li><li><font>Make another user a project lead on
guidestar.</font></li>
</ol>
<h3><font>CLEANING UP</font></h3>
<ol>
<li><font>Go to /admin/group-types</font></li><li><font>Select the project group type</font></li><li><font>Delete this group type. Should get prompted to delete sub
projects group type.</font></li><li><font>Delete the sub projects group type.</font></li><li><font>Should get prompt to delete the project lead rel
type</font></li><li><font>Delete the project lead rel type. Continue until you
delete the project group type.</font></li><li><font>Delete the ArsDigita group.</font></li><li><font>Go to /admin/rel-types/</font></li><li><font>Click on "View all roles"</font></li><li><font>Click on "Project Leader" - delete this
role</font></li><li><font>Click on "Employer" then on Employment
Relation</font></li><li><font>Delete the employment relation type.</font></li><li><font>Delete the employee, employer, and project_leader
roles</font></li><li><font>Delete any groups you created for the developer defined
type</font></li><li>
<font>Drop the developer defined type (in SQL*Plus):</font><pre><font>
exec acs_object_type.drop_type('developer_defined_test_type'); 
drop table developer_defined_test_types;
drop package developer_defined_test_type;
</font></pre>
</li>
</ol>
<hr>
<address><font><a href="mailto:mbryzek\@arsdigita.com">Michael
Bryzek</a></font></address>
<font>
<br><font size="-1">$&zwnj;Id: group-admin-pages-acceptance-test.html,v 1.4
2017/08/07 23:47:59 gustafn Exp $</font>
</font>
