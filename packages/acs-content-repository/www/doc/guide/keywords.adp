
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Content Repository Developer Guide: Subject Keywords
(Categories)}</property>
<property name="doc(title)">Content Repository Developer Guide: Subject Keywords
(Categories)</property>
<master>
<h2>Subject Keywords (Categories)</h2>
<strong>
<a href="../index">Content Repository</a> : Developer
Guide</strong>
<hr>
<h3>Overview</h3>
<p>
<em>Subject Keywords</em> are used to implement categorization
for the Content Management system. A Subject Keyword is a small
label, such as "Oracle Documentation" or "My
Favorite Foods", which can be associated with any number of
content items. Thus, content items may be grouped by arbitrary
categories. For example, assigning the Subject Keyword "My
Favorite Foods" to the content items "Potstickers",
"Strawberries" and "Ice Cream" would indicate
that all the three items belong in the same category - namely, the
category of the user&#39;s favorite foods. The actual physical
location of these items within the repository is irrelevant.</p>
<p>Subject Keywords may be nested to provide more detailed control
over categorization; for example, "My Favorite Foods" may
be further subdivided into "Healthy" and
"Unhealthy". Subject Keywords which have descendants are
referred to as "<em>Subject Categories</em>".</p>
<h3>Data Model</h3>
<p>The <kbd>content_keyword</kbd> object type is used to represent
Subject Keywords (see <kbd>content_keyword.sql</kbd>) The
<kbd>content_keyword</kbd> type inherits from
<kbd>acs_object</kbd>:</p>
<pre>
 acs_object_type.create_type ( supertype =&gt; 'acs_object', object_type
   =&gt; 'content_keyword', pretty_name =&gt; 'Content Keyword',
   pretty_plural =&gt; 'Content Keywords', table_name =&gt; 'cr_keywords',
   id_column =&gt; 'keyword_id', name_method =&gt; 'acs_object.default_name'
   ); 
</pre>

In addition, the <kbd>cr_keywords</kbd>
 table (see
<kbd>content-create.sql</kbd>
) contains extended attributes of
Subject Keywords:
<pre>
create table cr_keywords (
  keyword_id             integer
                         constraint cr_keywords_pk
                         primary key,
  heading                varchar2(600)
                         constraint cr_keywords_name_nil
                         not null,
  description            varchar2(4000)
);
</pre>

In <kbd>content-keyword.sql</kbd>
:
<pre>
attr_id := acs_attribute.create_attribute (
  object_type    =&gt; 'acs_object',
  attribute_name =&gt; 'heading',
  datatype       =&gt; 'string',
  pretty_name    =&gt; 'Heading',
  pretty_plural  =&gt; 'Headings'
); 

attr_id := acs_attribute.create_attribute (
  object_type    =&gt; 'content_keyword',
  attribute_name =&gt; 'description',
  datatype       =&gt; 'string',
  pretty_name    =&gt; 'Description',
  pretty_plural  =&gt; 'Descriptions'
);
</pre>
<p>Thus, each Subject Keyword has a <kbd>heading</kbd>, which is a
user-readable heading for the keyword, and a
<kbd>description</kbd>, which is a somewhat longer description of
the keyword.</p>
<p>The <kbd>cr_item_keyword_map</kbd> table (see
<kbd>content-create.sql</kbd>) is used to relate content items to
keywords:</p>
<pre>
create table cr_item_keyword_map (
  item_id          integer
                   constraint cr_item_keyword_map_item_fk
                   references cr_items
                   constraint cr_item_keyword_map_item_nil
                   not null,
  keyword_id       integer
                   constraint cr_item_keyword_map_kw_fk
                   references cr_keywords
                   constraint cr_item_keyword_map_kw_nil
                   not null
  constraint cr_item_keyword_map_pk
  primary key (item_id, keyword_id)
);
</pre>
<h3><a href="/api-doc/procs-file-view?path=packages/acs-content-repository/tcl/content-keyword-procs.tcl">
API Access</a></h3>
<p>The API used to access and modify content keywords are outlined
below. The function names are links that will take you to a more
detailed description of the function and its parameters.</p>
<table border="1" cellpadding="4" cellspacing="0">
<tr>
<th>Function/Procedure</th><th>Purpose</th><th>Description</th>
</tr><tr>
<td><a href="/api-doc/proc-view?proc=content::keyword::new">new</a></td><td>Create a new Subject Keyword</td><td>This is a standard <kbd>new</kbd> function, used to create a
new Subject Keyword. If the parent id is specified, the new keword
becomes a child of the parent keyword (which may now be called a
Subject Category)</td>
</tr><tr>
<td><a href="/api-doc/proc-view?proc=content::keyword::delete">delete</a></td><td>Delete a Subject Keyword</td><td>This is a standard <kbd>delete</kbd> function, used to delete a
Subject Keyword</td>
</tr><tr>
<td>
<a href="/api-doc/proc-view?proc=content::keyword::get_heading">get_heading</a><br><a href="/api-doc/proc-view?proc=content::keyword::set_heading">set_heading</a><br><a href="/api-doc/proc-view?proc=content::keyword::get_description">get_description</a><br><a href="/api-doc/proc-view?proc=content::keyword::set_description">set_description</a>
</td><td>Manipulate properties of the Keyword</td><td>You must use these functions to manipulate the properties of a
keyword. In the future, the data model will be updated to handle
internatiolization, but the API will not change.</td>
</tr><tr>
<td>
<a href="/api-doc/proc-view?proc=content::keyword::item_assign">item_assign</a><br><a href="/api-doc/proc-view?proc=content::keyword::item_unassign">item_unassign</a><br><a href="/api-doc/proc-view?proc=content::keyword::is_assigned">is_assigned</a>
</td><td>Assign Keywords to Items</td><td>These functions should be used to assign Subject Keywords to
content items, to unassign keywords from items, and to determine
whether a particular keyword is assigned to an item.
<p>The <kbd>is_assigned</kbd> function can be used to determine if
a keyword matches a content item, based on the <kbd>recurse</kbd>
parameter:</p><ul>
<li>If <kbd>recurse</kbd> is set to <kbd>'none'</kbd>,
<kbd>is_assigned</kbd> will return <kbd>'t'</kbd> if and
only if there is an exact assignment of the keyword to the
item.</li><li>If <kbd>recurse</kbd> is set to <kbd>'down'</kbd>,
<kbd>is_assigned</kbd> will return <kbd>'t'</kbd> if there
is an exact assignment of the keyword to the item, or if a narrower
keyword is assigned to the item. For example, a query whether
"Potstickers" is assigned the category "My Favorite
Foods" will return <kbd>'t'</kbd> even if
"Potstickers" is only assigned the category
"Healthy".</li><li>If <kbd>recurse</kbd> is set to <kbd>'up'</kbd>,
<kbd>is_assigned</kbd> will return <kbd>'t'</kbd> if there
is an exact assignment of the keyword to the item, or if a broader
Subject Category is assigned to the item. For example, a query
whether "Potstickers" is assigned the category
"Healthy" will return <kbd>'t'</kbd> even if
"Potstickers" is assigned the broader category "My
Favorite Foods".</li>
</ul>
</td>
</tr>
</table>
