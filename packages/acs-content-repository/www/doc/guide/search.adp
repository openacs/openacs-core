
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Content Repository Developer Guide: Search}</property>
<property name="doc(title)">Content Repository Developer Guide: Search</property>
<master>
<h2>Search</h2>
<strong>
<a href="../index">Content Repository</a> : Developer
Guide</strong>
<p>The content repository provides a consistent sitewide interface
for searching content. It uses Intermedia to index the
<kbd>content</kbd> column of <kbd>cr_revisions</kbd>) as well as
all the attribute columns for each content type.</p>
<h3>Searching Content</h3>
<p>The <kbd>content</kbd> column in <kbd>cr_revisions</kbd> may
contain data in any text or binary format. To accommodate searches
across multiple file types, the content repository uses an
Intermedia index with the INSO filtering option. The INSO filter
automatically detects the the file type of a binary object, and
extracts text from it for indexing. Most common file types are
supported, including PDF and Microsoft Word, and Excel and
PowerPoint.</p>
<p>Searching for content requires the same syntax as any text
index:</p>
<pre>
select
  score(1), revision_id, item_id
from
  cr_revisions r
where
  contains(content, 'company', 1) &gt; 0
</pre>
<p>The above query may be useful for an administrative interface
where you wish to search across all revisions, but in most cases
you only want to search live revisions:</p>
<pre>
select
  score(1), revision_id, item_id, content_item.get_path(item_id) url, title
from
  cr_revisions
where
  contains(content, 'company', 1) &gt; 0
and
  revision_id = content_item.get_live_revision(item_id)
</pre>
<p>The URL and title may be used to construct a hyperlink directly
to the item.</p>
<p>You may implement any number of variants on this basic query to
place additional constraints on the results, such as publication
date, content type, subject heading or a particular attribute (see
below).</p>
<p>Some limitations of the current implementation include:</p>
<ul>
<li>Multilingual searches are not enabled by default. You may
enable them for one more languages by setting the appropriate
Intermedia preferences when creating
<kbd>cr_rev_content_index</kbd>.</li><li>Some items are not appropriate to display
"stand-alone", but rather need to appear only in the
context of a container document (typically their parent in the
content repository). This is probably a limitation of
<kbd>content_item.get_path</kbd>: it should be possible to specify
an arbitrary function to return the path for items of a particular
content type, with <kbd>content_item.get_path</kbd> as the
default.</li>
</ul>
<h3>Searching Attributes</h3>
<p>This task is primarily handled to two Intermedia indices:</p>
<p>Providing a generic mechanism for searching attributes is
complicated by the fact that the attributes for each content type
are different. The content repository takes advantage of the XML
features in Oracle 8.1.6 to address this:</p>
<ol>
<li><p>After creating a new revision and inserting attributes into the
storage table for the content type and all its ancestors, you must
execute the <kbd>content_revision.index_attributes</kbd> procedure.
(Note that this cannot be called automatically by
<kbd>content_revision.new</kbd>, since the attributes in all
extended storage tables must be inserted first).</p></li><li><p>This procedure creates a row in the
<kbd>cr_revision_attributes</kbd> table, and writes an XML document
including all attributes into this row. A Java stored procedure
using the Oracle XML Parser for Java v2 is used to actually
generate the XML document.</p></li><li><p>A special Intermedia index configured to parse XML documents is
built on the column containing the XML documents for all
revisions.</p></li>
</ol>
<p>The Intermedia index allows you to use the WITHIN operator to
search on individual attributes if desired.</p>
<pre>
select 
  revision_id,score(1) 
from 
  cr_revisions 
where 
  contains(attributes, 'company WITHIN title', 1) &gt; 0
</pre>
<p>Some limitations of the current implementation include:</p>
<ol>
<li>A <kbd>USER_DATASTORE</kbd> associated with each row of the
<kbd>cr_items</kbd> table, which feeds Intermedia the contents of
the <kbd>content</kbd> column (a BLOB) for the <em>live</em>
revision of an item. This should theoretically be more efficient
for searching live content, especially in production environments
where content is revised often.</li><li>A second <kbd>USER_DATASTORE</kbd> associated with each row of
the <kbd>cr_items</kbd> table, which feeds Intermedia the XML
document representing all attributes for the <em>live</em> revision
of an item (from <kbd>cr_revision_attributes</kbd>).</li><li>The default XML document handler for the content repository
simply provides a flat file of all attributes. Content types should
also be able implement custom handlers, to allow the XML document
to reflect one-to-many relationships or special formatting of
attributes as well. The handler should specify a java class and
method, which a dispatch method can call by reflection.</li>
</ol>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last Modified: $&zwnj;Id: search.html,v 1.1.1.1.30.2 2017/04/21 14:53:08
gustafn Exp $
