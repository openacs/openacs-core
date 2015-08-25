
<property name="context">{/doc/acs-content-repository {Content Repository}} {Content Repository Developer Guide: Creating Content
Revisions}</property>
<property name="doc(title)">Content Repository Developer Guide: Creating Content
Revisions</property>
<master>
<h2>Creating Content Revisions</h2>
<p>At a basic level, creating a new revision of a content item
involves the following steps:</p>
<ol>
<li>Insert a row in the <tt>acs_objects</tt> table to create the
object.</li><li>Insert a corresponding row in the <tt>cr_revisions</tt> table
with the basic attributes for the revision.</li><li>Write the content data into the <tt>content</tt> BLOB column of
the <tt>cr_revisions</tt> table.</li><li>Insert a corresponding row into the attribute table of each
ancestor of the content type of the item. This is not applicable if
the content type is <b>Basic Item</b> or an immediate subtype
thereof.</li><li>Insert a corresponding row into the attribute table of the
content type of the item. This is not applicable if the content
type is <b>Basic Item</b>.</li>
</ol>
<h3>Use the Content Revision API to create a revision</h3>
<p>Content revisions are initialized using the
<tt>content_revision.new</tt> function. The only parameters
required to create the revision are a title, a content item ID, and
some text:</p>
<pre>
revision_id := content_revision.new( 
    title   =&gt; 'A Revision',
    item_id =&gt; :item_id,
    text    =&gt; 'Once upon a time Goldilocks crossed the street.
                Here comes a car...uh oh!  The End'
);
</pre>
<p>The <tt>item_id</tt> parameter is ID of the content item with
which the revision is associated.</p>
<p>The <tt>content_item.new</tt> function accepts a number of other
optional parameters: <tt>description</tt>, <tt>mime_type</tt>, and
<tt>publish_date</tt>. The standard <tt>creation_date</tt>,
<tt>creation_user</tt>, and <tt>creation_ip</tt> should be
specified for auditing purposes. Instead of the <tt>text</tt>
parameter, this function can be called with a <tt>data</tt>
parameter, in which <tt>data</tt> is a blob:</p>
<pre>
revision_id := content_revision.new(
    title         =&gt; 'A Revision',
    description   =&gt; 'A Description of a revision',
    mime_type     =&gt; 'text/html',
    publish_date  =&gt; to_date('Jan 22, 2000','Mon DD, YYYY'),
    item_id       =&gt; :item_id,
    data          =&gt; :blob_of_content,
    creation_date =&gt; sysdate,
    creation_user =&gt; :user_id,
    creation_ip   =&gt; :ip_address
);
</pre>
<h3>Insert additional attributes</h3>
<p>Given that there is no way (AFAIK) to pass variable parameters
to a PL/SQL function, there is no way to make
<tt>content_revision.new</tt> generic enough to support submission
of the attributes for all different content types. This leaves you
with three alternatives:</p>
<ol>
<li>Call <tt>content_revision.new</tt> followed by manual DML
statements to write data into the content BLOB and insert
attributes.</li><li>Write a PL/SQL package for each of your content types, which
encapsulates the above code.</li><li>Create revisions by inserting into the attribute view for each
content type.</li>
</ol>
<p>The last option is made possible by an <tt>instead of
insert</tt> trigger on the attribute view for each content type.
(An <em>attribute view</em> joins together the storage tables for
the ancestors of each content type, including <tt>acs_objects</tt>
and <tt>cr_revisions</tt>). Normally it is not possible to insert
into a view. Oracle allows you to create an <tt>instead of</tt>
trigger for a view, however, which intercepts the DML statement and
allows you to execute an arbitrary block of PL/SQL instead. The
code to create or replace the trigger is automatically generated
and executed with each call to
<tt>content_type.create_attribute</tt>. The trigger makes it
possible to create complete revisions with a single insert
statement:</p>
<pre>
insert into cr_revisionsx (
  item_id, revision_id, title
) values (
  18, 19, 'All About Revisions'
);
</pre>
<p>Because a special trigger is generated for each content type
that includes insert statements for all inherited tables, revisions
with extended attributes may be created in the same fashion:</p>
<pre>
insert into cr_imagesx (
  item_id, revision_id, title, height, width
) values (
  18, 19, 'A Nice Drawing', 300, 400
);
</pre>
<h3>Inserting content via file or text upload</h3>
<h3>Selecting a live revision</h3>
<p>The live revision of a content item can be obtained with the
<tt>content_item.get_live_revision</tt> function:</p>
<pre>
live_revision_id := content_item.get_live_revision(
    item_id =&gt; :item_id
);
</pre>
<p>The <tt>item_id</tt> identifies the content item with which the
revision is associated.</p>
<p>Likewise, the most recent revision of a content item can be
obtained with the <tt>content_item.get_latest_revision</tt>
function:</p>
<pre>
latest_revision_id := content_item.get_latest_revision(
    item_id =&gt; :item_id
);
</pre>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<p>Last Modified: $Id: revisions.html,v 1.1.1.1 2001/03/13 22:59:26
ben Exp $</p>
