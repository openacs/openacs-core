
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Storing Data in the Content Repository</h2>
<p>This document provides an introduction to using the content
repository for storing data (binary or text files) and associated
attributes. It describes how to store user portraits as an
example.</p>
<h3>Define an Item Type</h3>
<p>The first step towards using the content repository is to define
one or more <em>content types</em> for the data you wish to
manage.</p>
<p>The basic content item includes the following attributes:</p>
<ul>
<li>Title</li><li>Description</li><li>Publication or Posting Date</li><li>Author or Contributor</li><li>MIME Type</li><li>Binary or Text Data</li>
</ul>
<p>Most types of content require additional attributes. For a
photo, we probably also want to store the pixel width and height at
the very least:</p>
<pre>  create table images (
    image_id       integer
                   constraint images_image_id_fk
                   references cr_revisions
                   constraint images_pk
                   primary key,
    width          integer,
    height         integer
  );</pre>
<p>Content types are nothing more than standard ACS Objects that
inherit from <kbd>content_revision</kbd>:</p>
<pre>begin

 acs_object_type.create_type (
   supertype =&gt; 'content_revision',
   object_type =&gt; 'image',
   pretty_name =&gt; 'Image',
   pretty_plural =&gt; 'Images',
   table_name =&gt; 'images',
   id_column =&gt; 'image_id',
   name_method =&gt; 'acs_object.default_name'
 );

 acs_attribute.create_attribute (
   object_type =&gt; 'image',
   attribute_name =&gt; 'width',
   datatype =&gt; 'number',
   pretty_name =&gt; 'Width',
   pretty_plural =&gt; 'Widths'
 );

 acs_attribute.create_attribute (
   object_type =&gt; 'image',
   attribute_name =&gt; 'height',
   datatype =&gt; 'number',
   pretty_name =&gt; 'Height',
   pretty_plural =&gt; 'Heights'
 );

end;
/
show errors</pre>
<p>Note that content types always extend
<kbd>content_revision</kbd>, rather than <kbd>content_item</kbd>.
This is because we want to store multiple revisions of both the
actual data (in this case the image) as well as associated
attributes (the width and height of the image may vary among
revisions).</p>
<h3>Define a Relationship to a Target Object</h3>
<p>The content repository implements a flexible mechanism for
organizing data in a hierarchical fashion in a manner similar to a
file system. This would be useful if we ever decided to allow each
user to manage an entire personal photo gallery rather than a
single portrait.</p>
<p>In the simple case where each user is allowed a single portrait,
we can simply define a relationship between user and image as ACS
Objects:</p>
<pre>  acs_rel_type.create_role('user');
  acs_rel_type.create_role('portrait');

  acs_rel_type.create_type( rel_type =&gt; 'user_portrait_rel',
     pretty_name =&gt; 'User Portrait',
     pretty_plural =&gt; 'User Portraits',
     object_type_one =&gt; 'user',
     role_one =&gt; 'user',
     min_n_rels_one =&gt; 1,
     max_n_rels_one =&gt; 1,
     object_type_two =&gt; 'content_item',
     min_n_rels_two =&gt; 0,
     max_n_rels_two =&gt; 1
  );</pre>
<p>Note that the <kbd>user</kbd> object is related to a
<kbd>content_item</kbd> object rather than an <kbd>image</kbd>
object directly. Each <kbd>image</kbd> object represents only a
single revision of a portrait. Revisions always exist in the
context of an item.</p>
<h3>Store Objects</h3>
<p>Now we have defined both a content type and relationship type,
we can start storing portraits. The DML for processing a new
portrait upload form would look like this:</p>
<pre>  begin transaction
    :item_id := content_item.new(:name, :item_id, sysdate, NULL,                           '[ns_conn peeraddr]'); 
    # maybe have content_revision return the LOB locator so that it can
    # be used directly with blob_dml_file
    :revision_id := content_revision.new(:title, :description, $publish_date,                               :mime_type, NULL, :text, 'content_revision', 
                               :item_id, :revision_id);
    blob_dml_file update cr_revisions set content = empty_blob() ...
    :rel_id := acs_rel.new(...)</pre>
<h3>Retrieve Objects</h3>
<pre>  ns_ora write_blob ...</pre>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<p>Last Modified: $&zwnj;Id: storage.html,v 1.2 2017/08/07 23:47:47
gustafn Exp $</p>
