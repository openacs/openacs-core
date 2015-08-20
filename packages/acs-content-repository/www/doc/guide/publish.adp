
<property name="context">{/doc/acs-content-repository {Content Repository}} {Content Repository Developer Guide: Publishing
Content}</property>
<property name="doc(title)">Content Repository Developer Guide: Publishing
Content</property>
<master>

<body>
<h2>Publishing Content</h2><p>The content repository does not place any restrictions on the
methods employed for delivering content via a public server
infrastructure. Applications are free to query the repository and
process the data in any way desired.</p><p>Although there are no restrictions on publishing methodology,
the repository API is intended to facilitate generic template-based
publication, regardless of the specific presentation layer used.
The following diagram illustrates the steps typically involved in
such a publication process:</p><img src="flow.gif" border="1"><p>In general, there is an initial <em>resolution</em> step in
which the server must identify the appropriate content item and
then decide which template to actually parse. Following that is an
<em>execution</em> step, during which setup tasks associated with
the template are performed. Finally, the <em>merging</em> step
combines the data and layout into a rendered page.</p><h3>Matching URLs to Content Items</h3><p>The primary mechanism for matching URLs to Content Items are
<em>virtual URL handlers</em>, <tt>.vuh</tt> files. An explanation
of virtual URL handlers can be found in the tutorial on the
<a href="/doc/request-processor">Request Processor</a>.</p><p>Here is an example <tt>index.vuh</tt> file that you can adapt to
your own purposes:</p><pre>
# Get the paths

set the_url [ad_conn path_info]
set the_root $::acs::pageroot

# Get the IDs
set content_root \
  [db_string content_root "select content_item.get_root_folder from dual"]
set template_root \
  [db_string template_root "select content_template.get_root_folder from dual"]

# Serve the page
# DRB: Note that content::init modifies the local variable the_root, which is treated
# as though it's been passed by reference.   This requires that the redirect treat the
# path as an absolute path within the filesystem.
if { [content::init the_url the_root $content_root $template_root] } {
  set file "$the_root/$the_url"
  rp_internal_redirect -absolute_path $file
} else {
  ns_returnnotfound
}
</pre><p>The <tt>content_root</tt> and <tt>template_root</tt> parameters
select the content and template root folders. In the example, they
are just the default roots that the content repository initializes
on installation. If you want to store your content completely
independent from that of other packages, you can initialize your
own content root and pass that folder's ID on to
<tt>content::init</tt>.</p><p>To publish content through URLs that are underneath
<tt>/mycontent</tt> you need to do the following:</p><ol>
<li>Create a directory <tt>mycontent</tt> in your server's page
root and an <tt>index.vuh</tt> file in that directory.</li><li>Adapt the <tt>set content_root ...</tt> and <tt>set
template_root ..</tt> statements in the example above so that they
are being set to the content and template root folders that you
want to publish content from.</li><li>Change the <tt>set the_url ...</tt> statement so that the
variable <tt>the_url</tt> contains the absolute path to the content
item you wish to serve from your (or the default) content
root.</li>
</ol><p>If you use the example <tt>index.vuh</tt> file above unaltered
for requests to <tt>my_content</tt>, a request for
<tt>http://yourserver/mycontent/news/articles/42</tt> would request
the content item <tt>/news/articles/42</tt> from the content
repository on the default content root folder.</p><h3>Matching Content Items to Templates</h3><h3>Querying Content</h3><h3>Querying Attributes</h3><p>When you create a new content type or add an attribute to an
existing content type, a view is created (or recreated) that joins
the attribute tables for the entire chain of inheritance for that
content type. The view always has the same name as the attribute
table for the content table, with an "x" appended to distinguish it
from the table itself (for example, if the attribute table for
<b>Press Releases</b> is <tt>press_releases</tt>, then the view
will be named <tt>press_releasesx</tt>. Querying this view is a
convenient means of accessing any attribute associated with a
content item.</p><p>As a shortcut, the item's template may call
<tt>content::get_content</tt> in its Tcl file in order to
automatically retrieve the current item's attributes. The
attributes will be placed in a onerow datasource called
<tt>content</tt> . The template may then call
<tt>template::util::array_to_vars content</tt> in order to convert
the onerow datasource to local variables.</p><p>In addition to the "x" view, the Content Repository creates an
"i" view, which simplifies the creation of new revisions. The "i"
view has the same name as the content table, with "i" appended at
the end. You may insert into the view as if it was a normal table;
the insert trigger on the view takes care of inserting the actual
values into the content tables.</p><h3>Querying Additional Data</h3><p>Templates often display more than simple content attributes.
Additional queries may be necessary to obtain data about related
objects not described directly in attribute tables. The setup code
associated with a template typically performs these queries after
the initial query for any needed attributes.</p><h3>Merging Data with Templates</h3><h3>Returning Output</h3><ol>
<li>Write to the file system</li><li>Service public requests directly</li>
</ol><hr><a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a><br>
Last Modified: $Id: publish.html,v 1.4 2013/04/12 16:12:56 gustafn
Exp $
</body>
