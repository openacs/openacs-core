
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Content Repository Design}</property>
<property name="doc(title)">Content Repository Design</property>
<master>
<h2>Content Repository Design</h2>
<strong>
<a href="/doc">ACS Documentation</a> : <a href="index">Content Repository</a>
</strong>
<h3>I. Essentials</h3>
<ul><li><a href="requirements">Feature Requirements
Document</a></li></ul>
<h3>II. Introduction</h3>
<p>Serving <em>content</em> is a basic function of any web site.
Common types of content include:</p>
<ul>
<li>Journal articles and stories</li><li>Documentation</li><li>News reports</li><li>Product reviews</li><li>Press releases</li><li>Message board postings</li><li>Photographs</li>
</ul>
<p>Note that the definition of content is not limited to what is
produced by the publisher. User-contributed content such as
reviews, comments, or message board postings may come to dominate
active community sites.</p>
<p>Regardless of its type or origin, it is often useful for
developers, publishers and users to handle all content in a
consistent fashion. Developers benefit because they can base all
their content-driven applications on a single core API, thereby
reducing the need for custom (and often redundant) development.
Publishers benefit because they can subject all types of content to
the same management and production practices, including access
control, workflow, categorization and syndication. Users benefit
because they can enjoy a single interface for searching, browsing
and managing their own contributions.</p>
<p>The content repository itself is intended <em>only</em> as a
common substrate for developing content-driven applications. It
provides the developer with a core set of content-related
services:</p>
<ul>
<li>Defining arbitrary content types.</li><li>Common storage of content items (each item consists of a text
or binary data with additional attributes as specified by the
content type).</li><li>Establishing relationships among items of any type.</li><li>Versioning</li><li>Consistent interaction with other services included in the ACS
core, including permissions, workflow and object
relationships.</li><li>Categorization</li><li>Searching</li>
</ul>
<p>As a substrate layer, the content repository is not intended to
ever have its own administrative or user interface. ACS modules and
custom applications built on the repository remain responsible for
implementing an appropriate interface. (Note that the ACS Content
Management System provides a general interface for interacting with
the content repository).</p>
<h3>III. Historical Considerations</h3>
<p>The content repository was originally developed in the Spring of
2000 as a standalone data model. It was based on an earlier custom
system developed for an ArsDigita client. Many of the principle
design features of the original data model were also reflected in
the ACS Objects system implemented in the ACS 4.0 core. The content
repository was subsequently rewritten as an extension of ACS
Objects.</p>
<h3>V. Design Tradeoffs</h3>
<p>The content repository is a direct extension of the core ACS
Object Model. As such the same design tradeoffs apply.</p>
<p>The content repository stores all revisions of all content items
in a single table, rather than maintaining separate tables for
"live" and other revisions. The single-table approach
dramatically simplifies most operations on the repository,
including adding revisions, marking a "live" revision,
and maintaining a full version history. The drawback of this
approach is that accessing live content is less efficient. Given
the ID of a content item, it is not possible to directly access the
live content associated with that item. Instead, an extra join to
the revisions table is required. Depending on the production habits
of the publisher, the amount of live content in the repository may
be eclipsed by large numbers of infrequently accessed working
drafts. The impact of this arrangement is minimized by storing the
actual content data in a separate tablespace (preferably on a
separate disk) from the actual revisions table, reducing its size
and allows the database server to scan and read it more
efficiently.</p>
<h3>VI. Further Reading</h3>
<p>The <a href="object-model">Object Model</a> provides a
graphic overview of how the content repository is designed.
The model links to pages of the API Guide that describe individual
objects. The Developer Guide describes how to address common
development tasks using the content repository.</p>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last Modified: $&zwnj;Id: design.html,v 1.2 2017/08/07 23:47:47 gustafn
Exp $
