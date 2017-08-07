
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Content Repository Developer Guide: Defining Content
Types}</property>
<property name="doc(title)">Content Repository Developer Guide: Defining Content
Types</property>
<master>
<h2>Defining Content Types</h2>
<strong>
<a href="../index">Content Repository</a> : Developer
Guide</strong>
<p>The content repository requires you to define each type of
content supported by your supplication. Content types are defined
as <a href="?">ACS Object Types</a>, and may be created in the same
fashion as any other object type. This page provides some specific
examples and details related to defining ACS object types in the
context of the content repository.</p>
<h3>Determine content attributes</h3>
<p>A content item typically consists of two components:</p>
<ol>
<li>Text or binary data stored as a single object</li><li>Structured attributes stored as distinct values</li>
</ol>
<p>Note that a content type does <em>not</em> have to store its
primary content in the <kbd>BLOB</kbd> column of the
<kbd>cr_revisions</kbd> table. There is some additional overhead
associated with retrieving small passages of text from the BLOB
column compared to an attribute column. In most cases the
difference is trivial (fewer than about 10 microseconds), but if
many items must be queried at the same time the difference may
become significant. If the primary content will always be small, it
is perfectly acceptable to store the content in an attribute column
instead.</p>
<p>Basic attributes for all content types are stored in the
<kbd>cr_revisions</kbd> (note that they are stored in the revisions
table so that attributes may be updated for each new revision of
the actual data). Most types of content require more than the basic
attributes. For example, when storing images you will usually want
to store the pixel height and width so that images can be selected
and sorted by size, as well as displayed efficiently.</p>
<h3>Create an attribute table</h3>
<p>Extended attributes associated with ACS object types may be
stored as key-value pairs in a central table (generic storage), or
in a custom table whose primary key references the associated ACS
object ID (specific storage). To ensure efficient access to
attributes, the content repository API requires you to use specific
storage. Your table should have the form:</p>
<pre>
create table cr_<em>content_type</em> (
    <em>content_type</em>_id       integer
                          constraint cr_<em>content_type</em>_id_fk
                          references cr_revisions
                          constraint cr_<em>content_type</em>_pk
                          primary key,
    <em>attributes</em>...
);
</pre>
<p>Note that your extended attribute table must reference the
<kbd>cr_revisions</kbd> table, <em>not</em><kbd>cr_items</kbd>. As
mentioned above, this allows you to maintain multiple revisions of
the attribute data in tandem with revisions of the content object
itself.</p>
<h3>Use the Content Type API to create the content type</h3>
<p>To define a content type, you should write an SQL script to
create the content type and then add attributes to it:</p>
<pre>
declare
 attr_id        acs_attributes.attribute_id%TYPE;
begin

 -- create the content type
 content_type.create_type (
   content_type  =&gt; 'cr_press_release',
   pretty_name   =&gt; 'Press Release',
   pretty_plural =&gt; 'Press Releases',
   table_name    =&gt; 'cr_press_releases',
   id_column     =&gt; 'release_id'
 );

 -- create content type attributes
 attr_id := content_type.create_attribute (
   content_type   =&gt; 'cr_press_release',
   attribute_name =&gt; 'location',
   datatype       =&gt; 'text',
   pretty_name    =&gt; 'Location',
   pretty_plural  =&gt; 'Location',
   column_spec    =&gt; 'varchar2(1000)'
 );

 ...
</pre>
<p>The <kbd>content_type</kbd> methods use the core ACS Object Type
API to create an object type for each content type, and to add
attributes to the object type. In addition,
<kbd>content_type.create_type</kbd> will create the extended
attribute table with an appropriately defined primary key column
(referencing its supertype) if the table does not already exist.
Likewise, <kbd>content_type.create_attribute</kbd> will add a
column to the table if the column does not already exist.</p>
<p>Most importantly, the <kbd>content_type</kbd> methods call
<kbd>content_type.refresh_view</kbd> after each change to the
content type definition. Each content type must have an associated
attribute view named <kbd>
<em>table_name</em>x</kbd>, where
<em><kbd>table_name</kbd></em> is the name of the extended
attribute table for a particular content type. The view joins the
<kbd>acs_objects</kbd>, <kbd>cr_revisions</kbd>, and all extended
attribute tables in the class hierarchy of a particular content
type. This view may be used to query attributes when serving
content.</p>
<h3>Creating compund items</h3>
<p>In many cases your content items will serve as containers for
other items. You can include the set of allowable components as
part of a content type definition. See <a href="object-relationships">Object Relationships</a> for
details.</p>
<hr>
<a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
<p>Last Modified: $&zwnj;Id: types.html,v 1.1.1.1.30.1 2016/06/22
07:40:41 gustafn Exp $</p>
