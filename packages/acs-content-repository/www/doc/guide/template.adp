
<property name="context">{/doc/acs-content-repository {Content Repository}} {Content Repository Developer Guide: Applying
Templates}</property>
<property name="doc(title)">Content Repository Developer Guide: Applying
Templates</property>
<master>

<body>
<h2>Applying Templates</h2><p>The content repository allows you to associate templates with
both content types and individual content items. A template
determines how a content item is rendered when exported to the file
system or served directly to a client.</p><p>The content repository does not make any assumptions about the
type of templating system used by the application server with which
it is being used. Templates are simply made available to the
application server as text objects. The server is responsible for
merging the template with the actual content.</p><h3>Creating templates</h3><p>The content repository handle templates as a special class of
text object. The interface for handling templates builds on that of
simple content items:</p><pre>
template_id := content_template.new(
    name          =&gt; 'image_template',
    parent_id     =&gt; :parent_id
);
</pre><p>The name represents the tail of the location for that content
template. The parent ID must be another content item, or a subclass
of content item such as a folder.</p><p>
<tt>The content_template.new</tt> function accepts the standard
<tt>creation_date</tt>, <tt>creation_user</tt>, and
<tt>creation_ip</tt> auditing parameters.</p><p>Content items and templates are organized in two separate
hierarchies within the content repository. For example, you may
place all your press releases in the <tt>press</tt> folder under
the item root (having the ID returned by
<tt>content_item.get_root_folder</tt>). You may have 5 different
templates used to render press releases. These my be stored in the
<tt>press</tt> folder under the <em>template</em> root (having the
ID returned by <tt>content_template.get_root_folder</tt>).</p><p>Templates are placed under their own root to ensures that bare
templates are never accessible via a public URL. This is also done
because the relationship with the file system may be different for
templates than for content items. For example, templates may be
associated with additional code or resource files that developers
maintain under separate source control.</p><h3>Associating templates with content types</h3><p>You use the <tt>content_type.register_template</tt> procedure to
associate a template with a particular content type:</p><pre>
content_type.register_template(
  content_type =&gt; 'content_revision',
  template_id  =&gt; :template_id,
  use_context  =&gt; 'public',
  is_default   =&gt; 't'
);
</pre><p>The <tt>use_context</tt> is a simple keyword that specifies the
situation in which the template is appropriate. One general
context, <tt>public</tt>, is loaded when the content repository is
installed. Templates in this context are for presenting content to
users of the site. Some sites may wish to distinguish this further,
for example using <tt>intranet</tt>, <tt>extranet</tt> and
<tt>public</tt> contexts.</p><p>The <tt>is_default</tt> flag specifies that this template will
serve as the default template in the case that no template is
registered to a content item of this content type and this use
context. Any content type/context pair may have any number of
templates registered to it, but there can be only one default
template per pair.</p><p>To make a template the default template for a content
type/context pair:</p><pre>
content_type.set_default_template(
    content_type =&gt; 'content_revision',
    template_id  =&gt; :template_id,
    use_context  =&gt; 'public'
);
</pre><h3>Associating templates with content items</h3><p>Individual items may also be associated with templates using the
<tt>content_item.register_template</tt> procedure:</p><pre>
content_item.register_template(
  item_id     =&gt; :item_id,
  template_id =&gt; :template_id,
  use_context =&gt; 'intranet'
);
</pre><p>Unlike the case with content types, only one template may be
registered with a content item for a particular context.</p><p>The content management system uses this functionality to allow
publishers to choose templates for each content they create. For
example, a company may have three different templates for
presenting press releases. Depending on the subject, geographic
region or any other criterion, a different template may be used for
each press release.</p><h3>Retrieving the template for a content item</h3><p>The application server (AOLserver or servlet container) may use
the <tt>content_item.get_template</tt> function to determine the
proper template to use for rendering a page in any particular
context:</p><pre>
template_id := content_item.get_template(
    item_id     =&gt; :item_id, 
    use_context =&gt; 'public'
);

template_path := content_template.get_path(
    template_id =&gt; :template_id
);
</pre><p>In the case that no template is registered to given item/context
pair, <tt>content_item.get_template</tt> will return the default
template (if it exists) for the related content type/context
pair.</p><h3>Unregistering templates</h3><p>The procedure for disassociating templates with content types is
as follows:</p><pre>
content_type.unregister_template(
    content_type =&gt; 'content_revision',
    template_id  =&gt; :template_id,
    use_context  =&gt; 'intranet'
);
</pre><p>The corresponding procedure to disassociate templates with
content items is:</p><pre>
content_item.unregister_template(
    item_id     =&gt; :item_id,
    template_id =&gt; :template_id,
    use_context =&gt; 'admin'
);
</pre><hr><a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a><p>Last Modified: $Id: template.html,v 1.1.1.1 2001/03/13 22:59:26
ben Exp $</p>
</body>
