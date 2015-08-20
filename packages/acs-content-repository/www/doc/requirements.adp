
<property name="context">{/doc/acs-content-repository {Content Repository}} {Content Repository Requirements}</property>
<property name="doc(title)">Content Repository Requirements</property>
<master>

<body>
<h2>Content Repository Requirements</h2>
Karl Goldstein (<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>)<br><a href="#history">Revision History</a><h3>VI.A Requirements: Data Model</h3><p><a name="item" id="item"><b>5.0 MIME Types</b></a></p><p>The content repository must be able to store objects in any
format, both text and binary. MIME types provide a standard set of
codes for identifying the file format of each content item. For the
purpose of data integrity, the repository must have a canonical
list of MIME types that may be assigned to content items.</p><p><a name="type" id="type"><b>10.0 Content Types</b></a></p><p>A <em>content type</em> is characterized by a set of attributes
that may be associated with a text or binary content object.
Attributes are stored separately from their associated content
object, and as such may be indexed, searched, sorted and retrieved
independently. For example, attributes of a press release may
include a title, byline, and publication date.</p><p>The data model must support storage of descriptive information
for each content type:</p><blockquote>
<p>
<b>10.10</b> Content types must be associated with unique
keyword identifiers, such as <tt>press_release</tt>, so they can be
referenced in data tables, queries and procedural code.</p><p>
<b>10.20</b> Content types must be associated with singular and
plural descriptive labels, such as <b>Press Release</b> and
<b>Press Releases</b>, to simplify user recognition.</p><p>
<b>10.20</b> Content types may specify any number of
<em>attributes</em>. Attribute values are simple strings or
numbers.</p><p>
<b>10.30</b> Content types may inherit attributes from any other
other content type. For example, a regional press release may be a
subtype of the press release type. Regional press releases have a
<tt>region</tt> attribute in addition to the characteristics of a
regular press release.</p><p>
<b>10.40</b> Part of the definition of a content type may
include a description of the parent-child relationships allowed for
items of this type. For example, a <b>Press Release</b> may contain
one or more items of type <b>Image</b>, but it should not contain
any items of type <b>Internal Financial Status Report</b>.</p><p>
<b>10.60</b> A content type definition may include a list of
allowed file MIME types for items of this type.</p><p>
<b>10.70</b> A content type definition may include a list of
tokens to identify or flag relationships with other items. For
example, the content type definition for a chapter of a reference
manual may include the tokens <b>next</b>, <b>previous</b> and
<b>see_also</b>. Each type of relationship may include a minimum
and/or maximum number of relationships of this type that are
required for an item to be published.</p>
</blockquote><p><a name="item" id="item"><b>20.0 Content Items</b></a></p><p>Items are the fundamental building blocks of the content
repository. Each item represents a distinct text or binary content
object that is publishable to the web, such as an article, report,
message or photograph. An item my also include any number of
attributes with more structured data, such as title, source, byline
and publication date.</p><p>Content items have the following persistent characteristics
which the data model must support:</p><blockquote>
<p>
<b>20.10</b> Content items must have a simple unique identifier
so they can be related to other objects in the system.</p><p>
<b>20.20</b> Each content item consists of a set of attributes
and a single text or binary object.</p><p>
<b>20.25</b> All content items are associated with a few basic
attributes to facilitate searching and development of browser
interfaces to the content repository:</p><ul>
<li>A title</li><li>A brief description or summary</li><li>An author or contributor</li><li>A publication or posting date</li><li>A <em>distinguished</em> URL at which an item may be
accessed.</li><li>A MIME type</li>
</ul><p>
<b>20.30</b> Each content item must be an instance of a
particular <a href="#type">content type</a>. The content type
defines the attributes associated with the content item, in
addition to the basic ones described above.</p><p>
<b>20.40</b> A content item must have a unique, persistent URL
(Uniform Resource Locator) by which it is publicly accessible, such
as <tt>/press-releases/products/widget</tt>. To facilitate moving
of items within the repository, the item itself should only be
associated with the "tail" of the url, such as <tt>widget</tt>. The
absolute URL of the item is determined by its location within the
repository (See <a href="#organization">Content
Organization</a>).</p><p>
<b>20.50</b> It must be possible to specify the language of each
item.</p><p>
<b>20.60</b> It must be possible to maintain a revision history
for both the attributes and the text or binary object associated
with a content item.</p><p>
<b>20.70</b>. There must be a flexible mechanism for
implementing access control on individual items, based on granting
of permissions to groups or individual users.</p><p>
<b>20.80</b>. A content item may be associated with any number
of workflows.</p><p>
<b>20.90</b>. Content items may themselves be "containers" or
"parents" for other content items. For example, an <b>Article</b>
may contain multiple <b>Sections</b>.</p><p>
<b>20.95</b> Each item may be associated with any number of
related objects. The type and number of relationships must be
constrained by the content type of the item (See 10.70 above).</p>
</blockquote><p><a name="revision" id="revision"><b>30.0 Content
Revision</b></a></p><p>As mentioned above, each content item may be associated with any
number of revisions. The data model for revisions must support the
following:</p><blockquote>
<p>
<b>30.10</b>. A revision consists of the complete state of the
item as it existed at a certain point in time. This includes the
main text or binary object associated with the item, as well as all
attributes.</p><p>
<b>30.20</b>. The data model must be extensible so that
revisions for all content types (with any number of attributes) may
be stored and retrieved efficiently.</p>
</blockquote><p><a name="organization" id="organization"><b>40.0 Organization of
the Repository</b></a></p><blockquote>
<p>
<b>40.10</b>. The data model must support the hierarchical
organization of content items in a manner similar to a file
system.</p><p>
<b>40.20</b>. The URL of a content item should reflect its
location in the hierarchy. For example, a press release with the
URL <tt>/press-releases/products/new-widget</tt> is located at the
third level down from the root of the hierarchy.</p><p>
<a name="folder" id="folder"><b>40.20.5 Content
Folder</b></a>.</p><p>A <em>folder</em> is analogous to a folder or directory in a
file system. It represents a level in the content item hierarchy.
In the previous example, <tt>press-releases</tt> is a folder under
the repository root, and <tt>products</tt> is folder within that.
The description of a folder may include the following
information:</p><blockquote>
<p>
<b>40.20.5.10</b>. A URL-encoded name for building the path to
folders and individual items within the folder.</p><p>
<b>40.20.5.20</b>. A pointer to a content item that may serve as
the "index" for the folder (i.e. the item that is served when the
URL of the folder itself is accessed).</p><p>
<b>40.20.5.30</b>. A set of constraints on the number and type
of content items that may be stored in the folder.</p>
</blockquote><p>
<b>40.30</b>. It must be possible to create symbolic links or
shortcuts to content items, so they may be presented at more than
one URL or branch of the hierarchy.</p><blockquote>
<p><a name="folder" id="folder">
<b>40.30.5 Content Symbolic
Link</b>.</a></p><p><a name="folder" id="folder">A <em>symbolic link</em> is
analogous to a symlink, alias or shortcut in a file system. The
description of a symbolic link must include the following
information:</a></p><p><a name="folder" id="folder">
<b>40.30.5.10</b>. A URL-encoded
name for the symbolic link. As for folders and items, this only
represents the "tail" of the URL, with the full URL being
determined by the folder in which the link is located.</a></p><p><a name="folder" id="folder">
<b>40.30.5.20</b>. A pointer to a
target item which the symbolic link references..</a></p><p><a name="folder" id="folder">
<b>40.30.5.30</b>. A title or
label, which may be different from the title or label of the target
item.</a></p>
</blockquote>
</blockquote><p>
<a name="folder" id="folder"></a><a name="template" id="template"><b>50.0 Content Template</b></a>.</p><p>The content repository should provide a means of storing and
managing the templates that are merged with content items to render
output in HTML or other formats. Templates are assumed to be text
files containing static markup with embedded tags or code to
incorporate dynamic content in appropriate places. The data model
requirements for templates are a subset of those for content
items.</p><p>Because they typically need to reference a specific attributes,
a template is typically specific to a particular content types and
its subtypes.</p><h3>VI.B Requirements: Stored Procedure API</h3><p><b>100.10 MIME Types</b></p><p>Since a MIME type is a required attribute of each content item,
the repository must be capable of managing a list of recognized
MIME types for ensuring appropriate delivery and storage of
content.</p><blockquote>
<p>
<b>100.10.10</b>. Register a MIME type</p><p>
<b>100.10.20</b>. Set the description of a MIME type</p><p>
<b>100.10.30</b>. Get the description of a MIME type</p><p>
<b>100.10.40</b>. Determine whether a MIME type is text or
binary</p><p>
<b>100.10.50</b>. Get a list of registered MIME types</p><p>
<b>100.10.60</b>. Unregister a MIME type</p>
</blockquote><p>It is important to note that the role of MIME types in the
content repository is simply to describe the general file format of
each content item. Neither the data model nor the API support the
full range of allowed parameters for the general MIME types such as
<tt>text/plain</tt>.</p><p id="100-20"><b>100.20 Locales</b></p><p>The repository must have access to a list of recognized locales
for the purpose of publishing content items in multiple languages
and character sets.</p><p>All content in the repository is stored in UTF-8 to facilitate
searching and uniform handling of content. Locales may be specified
as user preferences to configure the user interface in the
following ways:</p><ul>
<li>language of content (when items are available in multiple
languages).</li><li>language of system messages (form labels, warnings, menu links,
etc.).</li><li>character set (text content converted from UTF-8 to the
specified character set).</li><li>number, date and currency format.</li><li>choice of layout, including templates, graphics and other
resources.</li>
</ul><p>Functional requirements for locales include:</p><blockquote>
<p>
<b>100.20.10</b>. Register a locale, including language,
territory and character set.</p><p>
<b>100.20.20</b>. Get the language of a specified locale.</p><p>
<b>100.20.10</b>. Get the character set code of a specified
locale using either Oracle or WETF/ISO/ANSI codes.</p><p>
<b>100.20.30</b>. Get the number, date and currency format of a
specified locale.</p><p>
<b>100.20.40</b>. Convert a text content item to a specified
locale (character set).</p><p>
<b>100.20.50</b>. Get a list of registered locales.</p><p>
<b>100.20.60</b>. Unregister a locale.</p>
</blockquote><p><b>100.30 Content Types</b></p><blockquote>
<p>
<b>100.30.10</b>. Create a content type, optionally specifying
that it inherits the attributes of another content type. Multiple
inheritance is not supported.</p><p>
<b>100.30.20</b>. Get and set the singular and plural proper
names for a content type.</p><p>
<b>100.30.30</b>. Create an attribute for a content type.</p><p>
<b>100.30.40</b>. Register a content type as a container for
another content type, optionally specifying a minimum and maximum
count of live items.</p><p>
<b>100.30.50</b>. Register a content type as a container for
another content type, optionally specifying a minimum and maximum
count of live items.</p><p>
<b>100.30.60</b>. Register a set of tags or tokens for labeling
child items of an item of a particular content type.</p><p>
<b>100.30.70</b>. Register a <a href="#template">template</a>
for use with a content type, optionally specifying a use context
("intranet", "extranet") which the template is appropriate to
use.</p><p>
<b>100.30.80</b>. Register a particular type of workflow to
associate with items of this content type by default.</p><p>
<b>100.30.90</b>. Register a MIME type as valid for a content
type. For example, the <b>Image</b> content type may only allow GIF
and JPEG file formats.</p><p>
<b>100.30.95</b> Register a relationship with another type of
object, specifying a token or name for the relationship type as
well as a minimum and/or maximum number of relationships of this
type that are required for the item to be published.</p>
</blockquote><p><b>100.40 Content Items</b></p><blockquote>
<p>
<b>100.40.10</b>. Create a new item, specifying a parent context
or the root of the repository by default.</p><p>
<b>100.40.15</b>. Rename an item.</p><p>
<b>100.40.17</b>. Copy an item to another location in the
repository.</p><p>
<b>100.40.20</b>. Move an item to another location in the
repository.</p><p>
<b>100.40.30</b>. Get the full path (ancestry of an item) up to
the root.</p><p>
<b>100.40.35</b>. Get the parent of an item.</p><p>
<b>100.40.40</b>. Determine whether an item may have a child of
a particular content type, based on the existing children of the
item and the constraints on the content type.</p><p>
<b>100.40.45</b>. Label a child item with a tag or token, based
on the set of tags registered for the content type of the container
item.</p><p>
<b>100.40.50</b>. Get the children of an item.</p><p>
<b>100.40.55</b>. Get the children of an item by type or
tag.</p><p>
<b>100.40.60</b>. Establish a generic relationship between any
object and a content item, optionally specifying a relationship
type.</p><p>
<b>100.40.70</b>. Create a revision.</p><p>
<b>100.40.80</b>. Mark a particular revision of an item as
"live".</p><p>
<b>100.40.83</b>. Specify a start and end time when an item
should be available.</p><p>
<b>100.40.85</b>. Clear the live revision attribute of an item,
effectively removing it from public view.</p><p>
<b>100.40.90</b>. Get a list of revisions for an item, including
modifying user, date modified and comments.</p><p>
<b>100.40.95</b>. Revert to an older revision (create a new
revision based on an older revision).</p>
</blockquote><p><b>100.50 Content Folders</b></p><p>The repository should allow for hierarchical arrangement of
content items in a manner similar to a file system. The API to meet
this general requirement focuses primarily on <a href="#folder">content folders</a>:</p><blockquote>
<p>
<b>100.50.10</b>. Create a <b>folder</b> for logical groups of
content items and other folders. The folder name becomes part of
the distinguished URL of any items it contains. Folders may be
created at the "root" or may be nested within other folders.</p><p>
<b>100.50.20</b>. Set a label and description for a folder.</p><p>
<b>100.50.30</b>. Get the label and description for a
folder.</p><p>
<b>100.50.40</b>. Get a list of folders contained within a
folder.</p><p>
<b>100.50.50</b>. Move a folder to another folder.</p><p>
<b>100.50.60</b>. Copy a folder to another folder.</p><p>
<b>100.50.70</b>. Create a <b>symbolic link</b> to a folder from
within another folder. The contents of the folder should be
accessible via the symbolic link as well as the regular path.</p><p>
<b>100.50.80</b>. Tag all live item revisions within a folder
with a common version descriptor (i.e. 'Version 1.0' or 'August 1
release'), for the purpose of versioning an entire branch of the
site. Folder objects themselves are <b>not</b> eligible for
versioning, since they are solely containers and do not have any
content other than the items they contain.</p><p>
<b>100.50.90</b>. Delete a folder if it is empty.</p>
</blockquote><p>Note that folders are simply a special type of content item, and
as such may receive the same object services as items, (namely
access control and workflow). In addition to the file-system
analogy afforded by folders, any type of content item may serve as
a contain for other content items (see below).</p><h3>Workflow</h3><p>The repository must offer integration with a workflow package
for managing the content production process.</p><p><b>100.60 Categorization</b></p><p>The repository must support a common hierarchical taxonomy of
subject classifications that may be applied to content items.</p><blockquote>
<p>
<b>100.60.10</b>. Create a new subject category.</p><p>
<b>100.60.20</b>. Create a new subject category as the child of
another subject category.</p><p>
<b>100.60.30</b>. Assign a subject category to a content
item.</p><p>
<b>100.60.40</b>. Remove a subject category from an item.</p><p>
<b>100.60.50</b>. Get the subject categories assigned to a
content item.</p>
</blockquote><h3>Search</h3><p>The repository must have a standard means of indexing and
searching all content.</p><h3>Access Control</h3><p>The repository must have a means of restricting access on an
item-by-item basis.</p><h3>VI.C Requirements: Presentation Layer API</h3><p>The presentation layer must have access to a subset of the
stored procedure API in order to search and retrieve content
directly from the repository if desired.</p><h3><a name="history" id="history">Revision History</a></h3><table cellspacing="0" cellpadding="4" border="1">
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
</table><hr><a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a><br>
Last Modified: $Id: requirements.html,v 1.2 2003/12/11 21:39:47
jeffd Exp $
</body>
