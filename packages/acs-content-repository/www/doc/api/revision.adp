
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Package: content_revision}</property>
<property name="doc(title)">Package: content_revision</property>
<master>
<h2>content_revision</h2>
<p>
<a href="../index">Content Repository</a> :
content_revision</p>
<hr>
<ul>
<li><a href="#overview">Overview</a></li><li><a href="#related">Related Objects</a></li><li><a href="#api">API</a></li>
</ul>
<p> </p>
<h3><a name="overview">Overview</a></h3>
<p>Content revisions contain the data for content items. There is a
many to one relationship between content revisions and content
items. There is at most one "live" revision for every
content item though. For example, there may be 5 revisions of the
review for the movie "Terminator," yet only one of these
may be live on the website at a given time.</p>
<p> </p>
<h3><a name="related">Related Objects</a></h3>

See also: {content_item }
<p> </p>
<h3><a name="api">API</a></h3>
<ul>
<li>
<font size="+1">Function:</font> content_revision.copy
<p>Creates a new copy of an attribute, including all attributes</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">revision_id:</th><td>  </td><td>The id of the revision to copy</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function copy (
  revision_id   in cr_revisions.revision_id%TYPE,
  copy_id       in cr_revisions.revision_id%TYPE default null
) return cr_revisions.revision_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_revision.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_revision.export_xml
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function export_xml (
  revision_id IN cr_revisions.revision_id%TYPE
) return cr_xml_docs.doc_id%TYPE;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_revision.get_number
<p>Return the revision number of the specified revision, according
to the chronological order in which revisions have been added for
this item.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The number of the revision</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">revision_id:</th><td>  </td><td>The id the revision</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_number (
  revision_id   in cr_revisions.revision_id%TYPE
) return number;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_revision.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_revision.import_xml
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function import_xml (
  item_id IN cr_items.item_id%TYPE,
  revision_id IN cr_revisions.revision_id%TYPE,
  doc_id IN number
) return cr_revisions.revision_id%TYPE;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_revision.new
<p>Create a new revision for an item.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the newly created revision</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">title:</th><td>  </td><td>The revised title for the item</td>
</tr><tr>
<th align="right" valign="top">description:</th><td>  </td><td>A short description of this revision, 4000 characters
maximum</td>
</tr><tr>
<th align="right" valign="top">publish_date:</th><td>  </td><td>Publication date.</td>
</tr><tr>
<th align="right" valign="top">mime_type:</th><td>  </td><td>The revised mime type of the item, defaults to
'text/plain'</td>
</tr><tr>
<th align="right" valign="top">nls_language:</th><td>  </td><td>The revised language of the item, for use with Intermedia
searching</td>
</tr><tr>
<th align="right" valign="top">data:</th><td>  </td><td>The blob which contains the body of the revision</td>
</tr><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The id of the item being revised</td>
</tr><tr>
<th align="right" valign="top">revision_id:</th><td>  </td><td>The id of the new revision. A new id will be allocated by
default</td>
</tr><tr>
<th align="right" valign="top">creation_date:</th><td>  </td><td>As in <kbd>acs_object.new</kbd>
</td>
</tr><tr>
<th align="right" valign="top">creation_ip:</th><td>  </td><td>As in <kbd>acs_object.new</kbd>
</td>
</tr><tr>
<th align="right" valign="top">creation_user:</th><td>  </td><td>As in <kbd>acs_object.new</kbd>
</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function new (
  title         in cr_revisions.title%TYPE,
  description   in cr_revisions.description%TYPE default null,
  publish_date  in cr_revisions.publish_date%TYPE default sysdate,
  mime_type     in cr_revisions.mime_type%TYPE default 'text/plain',
  nls_language  in cr_revisions.nls_language%TYPE default null,
  data          in cr_revisions.content%TYPE,
  item_id       in cr_items.item_id%TYPE,
  revision_id   in cr_revisions.revision_id%TYPE default null,
  creation_date in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user in acs_objects.creation_user%TYPE
                           default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null
) return cr_revisions.revision_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.new, content_item.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_revision.read_xml
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function read_xml (
  item_id IN number,
  revision_id IN number,
  clob_loc IN clob
) return number as language
  java
name
  'com.arsdigita.content.XMLExchange.importRevision(
     java.lang.Integer, java.lang.Integer, oracle.sql.CLOB
  ) return int';

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_revision.write_xml
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function write_xml (
  revision_id IN number,
  clob_loc IN clob
) return number as language
  java
name
  'com.arsdigita.content.XMLExchange.exportRevision(
     java.lang.Integer, oracle.sql.CLOB
  ) return int';

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_revision.delete
<p>Deletes the revision.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">revision_id:</th><td>  </td><td>The id of the revision to delete</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure delete (
  revision_id   in cr_revisions.revision_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_revision.new, acs_object.delete</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_revision.index_attributes
<p>Generates an XML document for insertion into
cr_revision_attributes, which is indexed by Intermedia for
searching attributes.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">revision_id:</th><td>  </td><td>The id of the revision to index</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure index_attributes(
  revision_id IN cr_revisions.revision_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_revision.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_revision.replace
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure replace(
  revision_id number, search varchar2, replace varchar2)
as language
  java
name
  'com.arsdigita.content.Regexp.replace(
    int, java.lang.String, java.lang.String
   )';

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_revision.to_html
<p>Converts a revision uploaded as a binary document to html</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">revision_id:</th><td>  </td><td>The id of the revision to index</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure to_html (
  revision_id IN cr_revisions.revision_id%TYPE
);

</kbd></pre></td></tr>
</table>
</li>
</ul>
<p> </p>

Last Modified: $&zwnj;Id: revision.html,v 1.1.1.1.30.2 2016/06/22
07:40:41 gustafn Exp $
