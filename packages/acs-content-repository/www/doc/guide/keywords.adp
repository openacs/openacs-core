
<property name="context">{/doc/acs-content-repository {Content Repository}} {Content Repository Developer Guide: Subject Keywords
(Categories)}</property>
<property name="doc(title)">Content Repository Developer Guide: Subject Keywords
(Categories)</property>
<master>
<h2>Subject Keywords (Categories)</h2>
<hr>
<h3>Overview</h3>
<p>
<em>Subject Keywords</em> are used to implement categorization
for the Content Management system. A Subject Keyword is a small
label, such as "Oracle Documentation" or "My Favorite Foods", which
can be associated with any number of content items. Thus, content
items may be grouped by arbitrary categories. For example,
assigning the Subject Keyword "My Favorite Foods" to the content
items "Potstickers", "Strawberries" and "Ice Cream" would indicate
that all the three items belong in the same category - namely, the
category of the user's favorite foods. The actual physical location
of these items within the repository is irrelevant.</p>
<p>Subject Keywords may be nested to provide more detailed control
over categorization; for example, "My Favorite Foods" may be
further subdivided into "Healthy" and "Unhealthy". Subject Keywords
which have descendants are referred to as "<em>Subject
Categories</em>".</p>
<h3>Data Model</h3>
<p>The <tt>content_keyword</tt> object type is used to represent
Subject Keywords (see <tt>content_keyword.sql</tt>) The
<tt>content_keyword</tt> type inherits from
<tt>acs_object</tt>:</p>
<pre>
 acs_object_type.create_type ( supertype =&gt; 'acs_object', object_type
   =&gt; 'content_keyword', pretty_name =&gt; 'Content Keyword',
   pretty_plural =&gt; 'Content Keywords', table_name =&gt; 'cr_keywords',
   id_column =&gt; 'keyword_id', name_method =&gt; 'acs_object.default_name'
   ); 
</pre>

In addition, the <tt>cr_keywords</tt>
 table (see
<tt>content-create.sql</tt>
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

In <tt>content-keyword.sql</tt>
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
<p>Thus, each Subject Keyword has a <tt>heading</tt>, which is a
user-readable heading for the keyword, and a <tt>description</tt>,
which is a somewhat longer description of the keyword.</p>
<p>The <tt>cr_item_keyword_map</tt> table (see
<tt>content-create.sql</tt>) is used to relate content items to
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
<td><a href="/api-doc/proc-view?proc=content::keyword::new">new</a></td><td>Create a new Subject Keyword</td><td>This is a standard <tt>new</tt> function, used to create a new
Subject Keyword. If the parent id is specified, the new keword
becomes a child of the parent keyword (which may now be called a
Subject Category)</td>
</tr><tr>
<td><a href="/api-doc/proc-view?proc=content::keyword::delete">delete</a></td><td>Delete a Subject Keyword</td><td>This is a standard <tt>delete</tt> function, used to delete a
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
<p>The <tt>is_assigned</tt> function can be used to determine if a
keyword matches a content item, based on the <tt>recurse</tt>
parameter:</p><ul>
<li>If <tt>recurse</tt> is set to <tt>'none'</tt>,
<tt>is_assigned</tt> will return <tt>'t'</tt> if and only if there
is an exact assignment of the keyword to the item.</li><li>If <tt>recurse</tt> is set to <tt>'down'</tt>,
<tt>is_assigned</tt> will return <tt>'t'</tt> if there is an exact
assignment of the keyword to the item, or if a narrower keyword is
assigned to the item. For example, a query whether "Potstickers" is
assigned the category "My Favorite Foods" will return <tt>'t'</tt>
even if "Potstickers" is only assigned the category "Healthy".</li><li>If <tt>recurse</tt> is set to <tt>'up'</tt>,
<tt>is_assigned</tt> will return <tt>'t'</tt> if there is an exact
assignment of the keyword to the item, or if a broader Subject
Category is assigned to the item. For example, a query whether
"Potstickers" is assigned the category "Healthy" will return
<tt>'t'</tt> even if "Potstickers" is assigned the broader category
"My Favorite Foods".</li>
</ul>
</td>
</tr>
</table>
