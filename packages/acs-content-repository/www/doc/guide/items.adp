
<property name="context">{/doc/acs-content-repository {Content Repository}} {Content Repository Developer Guide: Creating Content
Items}</property>
<property name="doc(title)">Content Repository Developer Guide: Creating Content
Items</property>
<master>

<body>
<h2>Creating Content Items</h2><h3>Use the Content Item API to create the item</h3><p>Content items are initialized using the
<tt>content_item.new</tt> function. A name is the only parameter
required to create an item:</p><pre>
item_id := content_item.new( name =&gt; 'my_item' );
</pre><p>The name represents the tail of the URL for that content item.
In most cases you will want to create items in a particular context
with the repository hierarchy:</p><pre>
item_id := content_item.new(
   name      =&gt; 'my_item', 
   parent_id =&gt; :parent_id
);
</pre><p>The parent ID must be another content item, or a subclass of
content item such as a folder.</p><p>The <tt>content_item.new</tt> function accepts a number of other
optional parameters. The standard <tt>creation_date</tt>,
<tt>creation_user</tt> and <tt>creation_ip</tt> should be specified
for auditing purposes. You can also create the initial revision and
publish text items in a single step:</p><pre>
item_id := content_item.new(
   name      =&gt; 'my_item', 
   parent_id =&gt; :parent_id,
   title     =&gt; 'My Item',
   text      =&gt; 'Once upon a time Goldilocks crossed the street.  
                 Here comes a car...uh oh!  The End',
   is_live   =&gt; 't'
);
</pre><p>If either the title or text are not null, the function will
create the first revision of the item. It will also mark the item
as live if the <tt>is_live</tt> parameter is true. The alternative
to this one step method is to create a content item and then add a
revision using the Content Revision API.</p><h3>Publishing a content item</h3><p>If a content item has at least one revision, then it can be
published by calling the <tt>content_item.set_live_revision</tt>
procedure, which takes as input a <tt>revision_id</tt>:</p><pre>
content_item.set_live_revision( revision_id =&gt; :revision_id );
</pre><hr><a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a><p>Last Modified: $Id: items.html,v 1.1.1.1 2001/03/13 22:59:26 ben
Exp $</p>
</body>
