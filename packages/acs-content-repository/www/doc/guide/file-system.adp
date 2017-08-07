
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Content Repository Developer Guide: Organizing Content
Items}</property>
<property name="doc(title)">Content Repository Developer Guide: Organizing Content
Items</property>
<master>
<h2>Organizing Content Items</h2>
<strong>
<a href="/doc">ACS Documentation</a> : <a href="../index">Content Repository</a> : Developer Guide</strong>
<p>The content repository organizes content items in a hierarchical
structure similar to a file system. You manage content items in the
repository using the same basic operations as in a file system:</p>
<ul>
<li>A freshly installed content repository consists of a single
"root" folder (analogous to the root directory
<kbd>/</kbd> in UNIX or an empty partition in Windows or
MacOS).</li><li>You organize items by creating subfolders under the root.</li><li>You can move or copy items from one folder to another.</li><li>You can create "links" or "shortcuts" for
items to make them accessible from within other directories.</li><li>Each item has a "file name" and an absolute
"path" that is determined by its location on a particular
branch of the repository tree. For example, the path to an item
named <kbd>widget</kbd> in the folder <kbd>products</kbd> would be
<kbd>/products/widget</kbd>.</li>
</ul>
<p>The content repository adds an additional twist to a traditional
filesystem: <em>any</em> content item, not just a folder, may serve
as a container for any number of other content items. For example,
imagine a book consisting of a preface, a number of chapters and a
bibliography (which in turn may have any number of entries). The
book itself is a content item, in that it has attributes
(publisher, ISBN number, publication date, synopsis, etc.)
associated with it. It also is the logical container for all its
components.</p>
<p>It is important to note that folders are simply a special
subtype of content item. The content repository&#39;s
representation of a parent-child relationship between a folder and
the items it contains is no different from the relationship between
a book and its chapters. Folders may be thought of simply as
generic containers for grouping items that are not necessarily part
of a greater whole.</p>
<h3>An Example</h3>
<p>Consider a simple repository structure with the following
contents:</p>
<img src="organization.gif" height="360" width="440" border="1">
<p>Note the following:</p>
<ul>
<li>The root folder of the content repository has a special ID
which is returned by the function
<kbd>content_item.get_root_folder</kbd>.</li><li>Regular content items such as <kbd>index</kbd> and
<kbd>about</kbd> may be stored directly under the root folder.</li><li>The "About Us" page has a photo as a child item. Note
that the path to the photo is <kbd>/about/photo</kbd>. Internally,
the photo&#39;s <kbd>parent_id</kbd> (in the <kbd>cr_items</kbd>
table) is set to the <kbd>item_id</kbd> of the "About Us"
page.</li><li>The "Press" folder contains two items. Internally,
the <kbd>parent_id</kbd> of the "Press Index" and
"Release One" items are set to the <kbd>item_id</kbd> of
the "Press" folder.</li>
</ul>
<p>Note that the same effective organization could have been
achieved by creating the "Press Index" item under the
root, and having press releases as its children. Using the folder
approach may have the following advantages:</p>
<ul>
<li>Content management systems can take advantage of the folder
structure to implement an intuitive user interface analogous to
familiar desktop tools (Windows Explorer, MacOS Finder, etc.).</li><li>You can use the content repository API to constraint the type
of content that a folder may contain (except for the index page).
For example, it is possible to limit the contents of the
"Press" folder to items of type "Press
Release." See the <a href="../api/folder">Content
Folder</a> API for more details.</li>
</ul>
<h3>Using your own root</h3>
<p>By default, the content repository has one root folder for
content items and one for templates. In some situations, that is
not enough. For example, a package that can be instantiated several
times might wish to store the content for each instance in its own
content root. Creating your own content (and template) root also
has the advantage that you will not accidentally access another
package&#39;s content nor will another package access your content.
Not that that could do any harm, because you have secured all your
content through appropriate permissions.</p>
<p>We only talk about creating content roots from here on —
creating template roots is completely analogous. You create your
own content root by calling <kbd>content_folder.new</kbd> in
PL/SQL:</p>
<pre>
declare
  v_my_content_root integer;
begin
  v_my_content_root := content_folder.new(
     name =&gt; 'my_root', 
     label =&gt; 'My Root', 
     parent_id =&gt; 0
  );
  -- Store v_my_content_root in a safe place
end;
/ 
</pre>
<p>The important point is that you have to pass in <kbd>0</kbd> for
the <kbd>parent_id</kbd>. This <kbd>parent_id</kbd> is special in
that it indicates folders with no parent.</p>
<p>The content repository does not keep track of who created what
root folders. You have to do that yourself. In the above example,
you need to store the value <kbd>v_my_content_root</kbd> somewhere,
for example a table that is specific for your package, otherwise
you won&#39;t have a reliable way of accessing your new content
root.</p>
<p>With multiple content roots, there can be many items with
<kbd>item_path</kbd><kbd>'/news/article'</kbd> and you
need to tell the content repository which root you are talking
about. For example, to retrieve content through
<kbd>content_item.get_id</kbd>, you pass the id of your content
root as the <kbd>root_folder_id</kbd> parameter to specify the
content root under which the <kbd>item_path</kbd> should be
resolved.</p>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last Modified: $&zwnj;Id: file-system.html,v 1.1.1.1.30.2 2017/04/21
14:53:08 gustafn Exp $
