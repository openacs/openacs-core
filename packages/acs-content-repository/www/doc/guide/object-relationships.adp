
<property name="context">{/doc/acs-content-repository {Content Repository}} {Content Repository Developer Guide: Object
Relationships}</property>
<property name="doc(title)">Content Repository Developer Guide: Object
Relationships</property>
<master>
<h2>Object Relationships</h2>
<p>Many applications of the content repository require that content
items be related to each other as well as to other classes of
objects. Examples include:</p>
<ul>
<li>News stories may be linked to other stories on the same
topic.</li><li>An article may be linked to any number of photos or charts that
are embedded in the article.</li><li>A long article is divided into multiple sections, each of which
is intended for separate display.</li><li>Product reviews are linked to specific products.</li><li>User portraits are linked to specific users.</li>
</ul>
<p>The ACS kernel provides a standard, highly flexible data model
and API for relating objects to other objects. If you have a highly
specific problem and are developing your own user interface on the
content repository, you can use the ACS relationships framework
directly. The relationship framework in the content repository
itself is simply intended as a convenience for handling common
relationship situations involving content items.</p>
<h3>Parent-Child Relationships</h3>
<p>In many cases one content item may serve as a natural container
for another item. An article divided into sections, or a news story
with an associated photo are one example of this. These
"parent-child" relationships are handled by the basic hierarchical
organization of the content repository. Every item has a parent
item, represented internally by the <tt>parent_id</tt> column in
the <tt>cr_items</tt> table.</p>
<p>It is often desirable to constrain the number and content type
of child items. For example, the specifications for a news story
may only allow for a single photo. A structured report may have
exactly three sections. Furthermore, it may be necessary to
classify or identify child items of the same type. Clearly the
sections of a report would have a logical order in which they would
need to be presented to the user. The layout for a photo album may
have a special position for a "featured" photo.</p>
<table border="0" width="100%"><tr>
<td align="center"><img src="article.gif" border="1"></td><td align="center"><img src="photo.gif" border="1"></td>
</tr></table>
<p>The content repository accomodates these situations in the
following ways:</p>
<ul>
<li>An API procedure, <tt>content_type.register_child_type</tt>,
may be used to specify the minimum and maximum number of children
of a particular content type that an item may have. You may
optionally specify a "tag" for identifying child items of the same
type. For example, you may want to allow only 1 image with the
"featured" tag, and up to 8 other images without this.</li><li>A Boolean API function, <tt>content_item.is_valid_child</tt>,
which checks all registered child constraints on the content type
of an item and returns true if it is currently possible to add an
child of a particular type to tan item. Note that this function
does not protect against concurrent transactions; it is only
foolproof if you lock the <tt>cr_child_rels</tt> table
beforehand.</li><li>A mapping table, <tt>cr_child_rels</tt>, which contains two
attributes, <tt>order_n</tt> and <tt>relation_tag</tt>, that may be
used to characterize the parent-child relationship. Parent-child
relationships are themselves treated as ACS Objects, so this table
may be extended with additional attributes as required by the
developer.</li>
</ul>
<p>Note that there is no currently no explicit API to "add a
child." You specify the parent of an item upon creating it. You can
use the API procedure <tt>content_item.move</tt> to change the
parent of an item.</p>
<h3>Item-Object Relationships</h3>
<p>In addition to the relationships to their parents and children
in the content repository hierarchy, content items may be linked to
any number of other objects in the system. This may include
products, users or content items on related subjects.</p>
<p>The same need to constrain the possibilities for an item-object
relationship, as described above for parents and children, also
apply to items and objects in general. The content repository
provides a data model and API for managing these constraints that
parallels what is provided for parent-child relationships:</p>
<ul>
<li>An API procedure, <tt>content_type.register_relation_type</tt>,
may be used to specify the minimum and maximum number of relations
with a particular object type that an item may have. There is no
limitation on the type of objects that may be related to content
items. If you wish to relate content items to other content items,
however, the object type should specify a content type (a subtype
of <tt>content_revision</tt>) rather than simply
<tt>content_item</tt>. As for parent-child relationship
constraints, ou may optionally specify a "tag" for identifying
related objects of the same type.</li><li>A Boolean API function,
<tt>content_item.is_valid_relation</tt>, which checks all
registered constraints on the content type of an item and returns
true if it is currently possible to relate an object of a
particular type to an item.</li><li>A mapping table, <tt>cr_item_rels</tt>, which contains two
attributes, <tt>order_n</tt> and <tt>relation_tag</tt>, that may be
used to characterize the item-object relationship. Item-object
relationships are themselves treated as ACS Objects, so this table
may be extended with additional attributes as required by the
developer.</li>
</ul>
<h3>Extending Parent-Child and Item-Object Relationships</h3>
<p>The simple relation mechanisms described above may not be
sufficient for some applications. However, because both
relationships defined by the content repository are
<em>themselves</em> objects, you have the option to extend their
types as you would for any other ACS object.</p>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last modified: <tt>$Id: object-relationships.html,v 1.1.1.1
2001/03/13 22:59:26 ben Exp $</tt>
