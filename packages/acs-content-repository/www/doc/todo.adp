
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>To Do List for Content Management System</h2>
<pre>

Documentation

Write ASAP.

Sign In/Out

--Eventually need to use regular acs40 API (maintain existing interface)

Work Items 3

--Display deadlines highlighted depending on whether the deadline has
  passed
--Add ability to check items in and out in addition to simply finishing
  enabled tasks.

Site Map

--Tree widget is buggy (not updating correctly on delete, not showing blue
                        arrows in proper context, etc.) 1-Stas
--Improve design of folder listing (sortable by name, date, size, mod_time) Michael
--Symlink title is confusing (Stas)
--Ideally bookmark graphics show change to show items that are currently 
  marked.

Items

--UI around each item needs polishing (better display of revisions etc.) 
--support for display and editing of additional simple attributes 2
--for now just allow assignment of one template. 1-Karl
--We currently have no way of setting access controls (also applies to 
   folders). 1

Content Types

--Not much to do here, seems OK.
--Need UI for creating content types, adding attributes, etc. (3)

Subject Categories

--Need to reintegrate simple category table (depends on message catalog)
  Previous UI was functional, should be reusable.
-- 1

Message Catalog

--Remove as a module for now.

Users

--Should display the party hierarchy here, with tools for adding/removing
  users.  Parties and usersshould be markable to the clipboard so they can 
  be used in building workflow contexts and access control lists.
-- 2

Workflows

--index.tcl: Display a list of available workflows, add/remove users from
the eligible list for each transition, etc.
--reintegration with notifications!

Clipboard 

--think about improving UI for this. 2

</pre>
<p>Last Modified: $&zwnj;Id: todo.html,v 1.1.1.1 2001/03/13 22:59:26 ben
Exp $</p>
