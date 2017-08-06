
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Content Repository Requirements}</property>
<property name="doc(title)">Content Repository Requirements</property>
<master>
<h2>Content Repository Requirements</h2>

Karl Goldstein (<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
)<br>
<a href="#history">Revision History</a>
<h3>VI.A Requirements: Data Model</h3>
<p><a name="item" id="item"><strong>5.0 MIME Types</strong></a></p>
<p>The content repository must be able to store objects in any
format, both text and binary. MIME types provide a standard set of
codes for identifying the file format of each content item. For the
purpose of data integrity, the repository must have a canonical
list of MIME types that may be assigned to content items.</p>
<p><a name="type" id="type"><strong>10.0 Content
Types</strong></a></p>
<p>A <em>content type</em> is characterized by a set of attributes
that may be associated with a text or binary content object.
Attributes are stored separately from their associated content
object, and as such may be indexed, searched, sorted and retrieved
independently. For example, attributes of a press release may
include a title, byline, and publication date.</p>
<p>The data model must support storage of descriptive information
for each content type:</p>
<blockquote>
<p>
<strong>10.10</strong> Content types must be associated with
unique keyword identifiers, such as <kbd>press_release</kbd>, so
they can be referenced in data tables, queries and procedural
code.</p><p>
<strong>10.20</strong> Content types must be associated with
singular and plural descriptive labels, such as <strong>Press
Release</strong> and <strong>Press Releases</strong>, to simplify
user recognition.</p><p>
<strong>10.20</strong> Content types may specify any number of
<em>attributes</em>. Attribute values are simple strings or
numbers.</p><p>
<strong>10.30</strong> Content types may inherit attributes from
any other other content type. For example, a regional press release
may be a subtype of the press release type. Regional press releases
have a <kbd>region</kbd> attribute in addition to the
characteristics of a regular press release.</p><p>
<strong>10.40</strong> Part of the definition of a content type
may include a description of the parent-child relationships allowed
for items of this type. For example, a <strong>Press
Release</strong> may contain one or more items of type
<strong>Image</strong>, but it should not contain any items of type
<strong>Internal Financial Status Report</strong>.</p><p>
<strong>10.60</strong> A content type definition may include a
list of allowed file MIME types for items of this type.</p><p>
<strong>10.70</strong> A content type definition may include a
list of tokens to identify or flag relationships with other items.
For example, the content type definition for a chapter of a
reference manual may include the tokens <strong>next</strong>,
<strong>previous</strong> and <strong>see_also</strong>. Each type
of relationship may include a minimum and/or maximum number of
relationships of this type that are required for an item to be
published.</p>
</blockquote>
<p><a name="item" id="item"><strong>20.0 Content
Items</strong></a></p>
<p>Items are the fundamental building blocks of the content
repository. Each item represents a distinct text or binary content
object that is publishable to the web, such as an article, report,
message or photograph. An item my also include any number of
attributes with more structured data, such as title, source, byline
and publication date.</p>
<p>Content items have the following persistent characteristics
which the data model must support:</p>
<blockquote>
<p>
<strong>20.10</strong> Content items must have a simple unique
identifier so they can be related to other objects in the
system.</p><p>
<strong>20.20</strong> Each content item consists of a set of
attributes and a single text or binary object.</p><p>
<strong>20.25</strong> All content items are associated with a
few basic attributes to facilitate searching and development of
browser interfaces to the content repository:</p><ul>
<li>A title</li><li>A brief description or summary</li><li>An author or contributor</li><li>A publication or posting date</li><li>A <em>distinguished</em> URL at which an item may be
accessed.</li><li>A MIME type</li>
</ul><p>
<strong>20.30</strong> Each content item must be an instance of
a particular <a href="#type">content type</a>. The content type
defines the attributes associated with the content item, in
addition to the basic ones described above.</p><p>
<strong>20.40</strong> A content item must have a unique,
persistent URL (Uniform Resource Locator) by which it is publicly
accessible, such as <kbd>/press-releases/products/widget</kbd>. To
facilitate moving of items within the repository, the item itself
should only be associated with the "tail" of the url,
such as <kbd>widget</kbd>. The absolute URL of the item is
determined by its location within the repository (See <a href="#organization">Content Organization</a>).</p><p>
<strong>20.50</strong> It must be possible to specify the
language of each item.</p><p>
<strong>20.60</strong> It must be possible to maintain a
revision history for both the attributes and the text or binary
object associated with a content item.</p><p>
<strong>20.70</strong>. There must be a flexible mechanism for
implementing access control on individual items, based on granting
of permissions to groups or individual users.</p><p>
<strong>20.80</strong>. A content item may be associated with
any number of workflows.</p><p>
<strong>20.90</strong>. Content items may themselves be
"containers" or "parents" for other content
items. For example, an <strong>Article</strong> may contain
multiple <strong>Sections</strong>.</p><p>
<strong>20.95</strong> Each item may be associated with any
number of related objects. The type and number of relationships
must be constrained by the content type of the item (See 10.70
above).</p>
</blockquote>
<p><a name="revision" id="revision"><strong>30.0 Content
Revision</strong></a></p>
<p>As mentioned above, each content item may be associated with any
number of revisions. The data model for revisions must support the
following:</p>
<blockquote>
<p>
<strong>30.10</strong>. A revision consists of the complete
state of the item as it existed at a certain point in time. This
includes the main text or binary object associated with the item,
as well as all attributes.</p><p>
<strong>30.20</strong>. The data model must be extensible so
that revisions for all content types (with any number of
attributes) may be stored and retrieved efficiently.</p>
</blockquote>
<p><a name="organization" id="organization"><strong>40.0
Organization of the Repository</strong></a></p>
<blockquote>
<p>
<strong>40.10</strong>. The data model must support the
hierarchical organization of content items in a manner similar to a
file system.</p><p>
<strong>40.20</strong>. The URL of a content item should reflect
its location in the hierarchy. For example, a press release with
the URL <kbd>/press-releases/products/new-widget</kbd> is located
at the third level down from the root of the hierarchy.</p><p>
<a name="folder" id="folder"><strong>40.20.5 Content
Folder</strong></a>.</p><p>A <em>folder</em> is analogous to a folder or directory in a
file system. It represents a level in the content item hierarchy.
In the previous example, <kbd>press-releases</kbd> is a folder
under the repository root, and <kbd>products</kbd> is folder within
that. The description of a folder may include the following
information:</p><blockquote>
<p>
<strong>40.20.5.10</strong>. A URL-encoded name for building the
path to folders and individual items within the folder.</p><p>
<strong>40.20.5.20</strong>. A pointer to a content item that
may serve as the "index" for the folder (i.e. the item
that is served when the URL of the folder itself is accessed).</p><p>
<strong>40.20.5.30</strong>. A set of constraints on the number
and type of content items that may be stored in the folder.</p>
</blockquote><p>
<strong>40.30</strong>. It must be possible to create symbolic
links or shortcuts to content items, so they may be presented at
more than one URL or branch of the hierarchy.</p><blockquote>
<p><a name="folder" id="folder">
<strong>40.30.5 Content Symbolic
Link</strong>.</a></p><p><a name="folder" id="folder">A <em>symbolic link</em> is
analogous to a symlink, alias or shortcut in a file system. The
description of a symbolic link must include the following
information:</a></p><p><a name="folder" id="folder">
<strong>40.30.5.10</strong>. A
URL-encoded name for the symbolic link. As for folders and items,
this only represents the "tail" of the URL, with the full
URL being determined by the folder in which the link is
located.</a></p><p><a name="folder" id="folder">
<strong>40.30.5.20</strong>. A
pointer to a target item which the symbolic link
references..</a></p><p><a name="folder" id="folder">
<strong>40.30.5.30</strong>. A
title or label, which may be different from the title or label of
the target item.</a></p>
</blockquote>
</blockquote>
<p>
<a name="folder" id="folder"></a><a name="template" id="template"><strong>50.0 Content Template</strong></a>.</p>
<p>The content repository should provide a means of storing and
managing the templates that are merged with content items to render
output in HTML or other formats. Templates are assumed to be text
files containing static markup with embedded tags or code to
incorporate dynamic content in appropriate places. The data model
requirements for templates are a subset of those for content
items.</p>
<p>Because they typically need to reference a specific attributes,
a template is typically specific to a particular content types and
its subtypes.</p>
<h3>VI.B Requirements: Stored Procedure API</h3>
<p><strong>100.10 MIME Types</strong></p>
<p>Since a MIME type is a required attribute of each content item,
the repository must be capable of managing a list of recognized
MIME types for ensuring appropriate delivery and storage of
content.</p>
<blockquote>
<p>
<strong>100.10.10</strong>. Register a MIME type</p><p>
<strong>100.10.20</strong>. Set the description of a MIME
type</p><p>
<strong>100.10.30</strong>. Get the description of a MIME
type</p><p>
<strong>100.10.40</strong>. Determine whether a MIME type is
text or binary</p><p>
<strong>100.10.50</strong>. Get a list of registered MIME
types</p><p>
<strong>100.10.60</strong>. Unregister a MIME type</p>
</blockquote>
<p>It is important to note that the role of MIME types in the
content repository is simply to describe the general file format of
each content item. Neither the data model nor the API support the
full range of allowed parameters for the general MIME types such as
<kbd>text/plain</kbd>.</p>
<p id="100-20"><strong>100.20 Locales</strong></p>
<p>The repository must have access to a list of recognized locales
for the purpose of publishing content items in multiple languages
and character sets.</p>
<p>All content in the repository is stored in UTF-8 to facilitate
searching and uniform handling of content. Locales may be specified
as user preferences to configure the user interface in the
following ways:</p>
<ul>
<li>language of content (when items are available in multiple
languages).</li><li>language of system messages (form labels, warnings, menu links,
etc.).</li><li>character set (text content converted from UTF-8 to the
specified character set).</li><li>number, date and currency format.</li><li>choice of layout, including templates, graphics and other
resources.</li>
</ul>
<p>Functional requirements for locales include:</p>
<blockquote>
<p>
<strong>100.20.10</strong>. Register a locale, including
language, territory and character set.</p><p>
<strong>100.20.20</strong>. Get the language of a specified
locale.</p><p>
<strong>100.20.10</strong>. Get the character set code of a
specified locale using either Oracle or WETF/ISO/ANSI codes.</p><p>
<strong>100.20.30</strong>. Get the number, date and currency
format of a specified locale.</p><p>
<strong>100.20.40</strong>. Convert a text content item to a
specified locale (character set).</p><p>
<strong>100.20.50</strong>. Get a list of registered
locales.</p><p>
<strong>100.20.60</strong>. Unregister a locale.</p>
</blockquote>
<p><strong>100.30 Content Types</strong></p>
<blockquote>
<p>
<strong>100.30.10</strong>. Create a content type, optionally
specifying that it inherits the attributes of another content type.
Multiple inheritance is not supported.</p><p>
<strong>100.30.20</strong>. Get and set the singular and plural
proper names for a content type.</p><p>
<strong>100.30.30</strong>. Create an attribute for a content
type.</p><p>
<strong>100.30.40</strong>. Register a content type as a
container for another content type, optionally specifying a minimum
and maximum count of live items.</p><p>
<strong>100.30.50</strong>. Register a content type as a
container for another content type, optionally specifying a minimum
and maximum count of live items.</p><p>
<strong>100.30.60</strong>. Register a set of tags or tokens for
labeling child items of an item of a particular content type.</p><p>
<strong>100.30.70</strong>. Register a <a href="#template">template</a> for use with a content type, optionally
specifying a use context ("intranet",
"extranet") which the template is appropriate to use.</p><p>
<strong>100.30.80</strong>. Register a particular type of
workflow to associate with items of this content type by
default.</p><p>
<strong>100.30.90</strong>. Register a MIME type as valid for a
content type. For example, the <strong>Image</strong> content type
may only allow GIF and JPEG file formats.</p><p>
<strong>100.30.95</strong> Register a relationship with another
type of object, specifying a token or name for the relationship
type as well as a minimum and/or maximum number of relationships of
this type that are required for the item to be published.</p>
</blockquote>
<p><strong>100.40 Content Items</strong></p>
<blockquote>
<p>
<strong>100.40.10</strong>. Create a new item, specifying a
parent context or the root of the repository by default.</p><p>
<strong>100.40.15</strong>. Rename an item.</p><p>
<strong>100.40.17</strong>. Copy an item to another location in
the repository.</p><p>
<strong>100.40.20</strong>. Move an item to another location in
the repository.</p><p>
<strong>100.40.30</strong>. Get the full path (ancestry of an
item) up to the root.</p><p>
<strong>100.40.35</strong>. Get the parent of an item.</p><p>
<strong>100.40.40</strong>. Determine whether an item may have a
child of a particular content type, based on the existing children
of the item and the constraints on the content type.</p><p>
<strong>100.40.45</strong>. Label a child item with a tag or
token, based on the set of tags registered for the content type of
the container item.</p><p>
<strong>100.40.50</strong>. Get the children of an item.</p><p>
<strong>100.40.55</strong>. Get the children of an item by type
or tag.</p><p>
<strong>100.40.60</strong>. Establish a generic relationship
between any object and a content item, optionally specifying a
relationship type.</p><p>
<strong>100.40.70</strong>. Create a revision.</p><p>
<strong>100.40.80</strong>. Mark a particular revision of an
item as "live".</p><p>
<strong>100.40.83</strong>. Specify a start and end time when an
item should be available.</p><p>
<strong>100.40.85</strong>. Clear the live revision attribute of
an item, effectively removing it from public view.</p><p>
<strong>100.40.90</strong>. Get a list of revisions for an item,
including modifying user, date modified and comments.</p><p>
<strong>100.40.95</strong>. Revert to an older revision (create
a new revision based on an older revision).</p>
</blockquote>
<p><strong>100.50 Content Folders</strong></p>
<p>The repository should allow for hierarchical arrangement of
content items in a manner similar to a file system. The API to meet
this general requirement focuses primarily on <a href="#folder">content folders</a>:</p>
<blockquote>
<p>
<strong>100.50.10</strong>. Create a <strong>folder</strong> for
logical groups of content items and other folders. The folder name
becomes part of the distinguished URL of any items it contains.
Folders may be created at the "root" or may be nested
within other folders.</p><p>
<strong>100.50.20</strong>. Set a label and description for a
folder.</p><p>
<strong>100.50.30</strong>. Get the label and description for a
folder.</p><p>
<strong>100.50.40</strong>. Get a list of folders contained
within a folder.</p><p>
<strong>100.50.50</strong>. Move a folder to another folder.</p><p>
<strong>100.50.60</strong>. Copy a folder to another folder.</p><p>
<strong>100.50.70</strong>. Create a <strong>symbolic
link</strong> to a folder from within another folder. The contents
of the folder should be accessible via the symbolic link as well as
the regular path.</p><p>
<strong>100.50.80</strong>. Tag all live item revisions within a
folder with a common version descriptor (i.e. 'Version 1.0'
or 'August 1 release'), for the purpose of versioning an
entire branch of the site. Folder objects themselves are
<strong>not</strong> eligible for versioning, since they are solely
containers and do not have any content other than the items they
contain.</p><p>
<strong>100.50.90</strong>. Delete a folder if it is empty.</p>
</blockquote>
<p>Note that folders are simply a special type of content item, and
as such may receive the same object services as items, (namely
access control and workflow). In addition to the file-system
analogy afforded by folders, any type of content item may serve as
a contain for other content items (see below).</p>
<h3>Workflow</h3>
<p>The repository must offer integration with a workflow package
for managing the content production process.</p>
<p><strong>100.60 Categorization</strong></p>
<p>The repository must support a common hierarchical taxonomy of
subject classifications that may be applied to content items.</p>
<blockquote>
<p>
<strong>100.60.10</strong>. Create a new subject category.</p><p>
<strong>100.60.20</strong>. Create a new subject category as the
child of another subject category.</p><p>
<strong>100.60.30</strong>. Assign a subject category to a
content item.</p><p>
<strong>100.60.40</strong>. Remove a subject category from an
item.</p><p>
<strong>100.60.50</strong>. Get the subject categories assigned
to a content item.</p>
</blockquote>
<h3>Search</h3>
<p>The repository must have a standard means of indexing and
searching all content.</p>
<h3>Access Control</h3>
<p>The repository must have a means of restricting access on an
item-by-item basis.</p>
<h3>VI.C Requirements: Presentation Layer API</h3>
<p>The presentation layer must have access to a subset of the
stored procedure API in order to search and retrieve content
directly from the repository if desired.</p>
<h3><a name="history" id="history">Revision History</a></h3>
<table cellspacing="0" cellpadding="4" border="1">
<tr>
<th>Author</th><th>Date</th><th>Description</th>
</tr><tr>
<td nowrap="nowrap">Karl Goldstein</td><td nowrap="nowrap">9 August 2000</td><td>Initial draft.</td>
</tr><tr>
<td nowrap="nowrap">Karl Goldstein</td><td nowrap="nowrap">22 August 2000</td><td>Added to API section.</td>
</tr><tr>
<td nowrap="nowrap">Karl Goldstein</td><td nowrap="nowrap">19 September 2000</td><td>Added data model requirements, revised API requirements,
numbered all items.</td>
</tr><tr>
<td nowrap="nowrap">Karl Goldstein</td><td nowrap="nowrap">21 September 2000</td><td>Add requirements for relationships among content items and
other objects.</td>
</tr>
</table>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last Modified: $&zwnj;Id: requirements.html,v 1.2.22.1 2016/06/22
07:40:41 gustafn Exp $
