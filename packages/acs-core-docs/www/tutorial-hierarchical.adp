
<property name="context">{/doc/acs-core-docs {Documentation}} {Hierarchical data}</property>
<property name="doc(title)">Hierarchical data</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-notifications" leftLabel="Prev"
		    title="
Chapter 10. Advanced Topics"
		    rightLink="tutorial-vuh" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-hierarchical" id="tutorial-hierarchical"></a>Hierarchical
data</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="http://rubick.com:8002" target="_top">Jade Rubick</a> with help from many people in the OpenACS
community</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>One of the nice things about using the OpenACS object system is
that it has a built-in facility for tracking hierarchical data in
an efficient way. The algorithm behind this is called <code class="computeroutput">tree_sortkey.</code>
</p><p>Any time your tables are subclasses of the acs_objects table,
then you automatically get the ability to structure them
hierarchically. The way you do this is currently via the
<code class="computeroutput">context_id</code> column of
acs_objects (Note that there is talk of adding in a <code class="computeroutput">parent_id</code> column instead, because the use
of <code class="computeroutput">context_id</code> has been
ambiguous in the past). So when you want to build your hierarchy,
simply set the context_id values. Then, when you want to make
hierarchical queries, you can do them as follows:</p><pre class="programlisting">
      db_multirow categories blog_categories "
      SELECT
      c.*,
      o.context_id,
      tree_level(o.tree_sortkey)
      FROM
      blog_categories c,
      acs_objects o
      WHERE
      c.category_id = o.object_id
      ORDER BY
      o.tree_sortkey"
    
</pre><p>Note the use of the <code class="computeroutput">tree_level()</code> function, which gives you the
level, starting from 1, 2, 3...</p><p>Here's an example, pulling all of the children for a given
parent:</p><pre class="programlisting">
      SELECT 
      children.*,
      tree_level(children.tree_sortkey) -
        tree_level(parent.tree_sortkey) as level
      FROM 
      some_table parent, 
      some_table children
      WHERE 
      children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
      and parent.tree_sortkey &lt;&gt; children.tree_sortkey
      and parent.key = :the_parent_key;
      
</pre><p>The reason we substract the parent's tree_level from the child's
tree_level is that the tree_levels are global, so if you want the
parent's tree_level to start with 0, you'll want the subtraction in
there. This is a reason you'll commonly see magic numbers in
tree_sortkey SQL queries, like <code class="computeroutput">tree_level(children.tree_sortkey) - 4</code>. That
is basically an incorrect way to do it, and subtracting the
parent's tree_level is the preferred method.</p><p>This example does not include the parent. To return the entire
subtree including the parent, leave out the non-equals clause:</p><pre class="programlisting">
      SELECT
      subtree.*,
      tree_level(subtree.tree_sortkey) -
        tree_level(parent.tree_sortkey) as level
      FROM some_table parent, some_table subtree
      WHERE 
      subtree.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
      and parent.key = :the_parent_key;
    
</pre><p>If you are using the Content Repository, you get a similar
facility, but the <code class="computeroutput">parent_id</code>
column is already there. Note you can do joins with <code class="computeroutput">tree_sortkey</code>:</p><pre class="programlisting">
      SELECT
      p.item_id,
      repeat(:indent_pattern, (tree_level(p.tree_sortkey) - 5)* :indent_factor) as indent,
      p.parent_id as folder_id,
      p.project_name
      FROM pm_projectsx p, cr_items i
      WHERE p.project_id = i.live_revision
      ORDER BY i.tree_sortkey
    
</pre><p>This rather long thread explains <a class="ulink" href="http://openacs.org/forums/message-view?message_id=16799" target="_top">How tree_sortkeys work</a> and this paper <a class="ulink" href="http://www.yafla.com/papers/sqlhierarchies/sqlhierarchies2.htm" target="_top">describes the technique for tree_sortkeys</a>,
although the <a class="ulink" href="http://openacs.org/forums/message-view?message_id=112943" target="_top">OpenACS implementation has a few differences in the
implementation</a>, to make it work for many languages and the LIKE
construct in Postgres.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-notifications" leftLabel="Prev" leftTitle="Notifications"
		    rightLink="tutorial-vuh" rightLabel="Next" rightTitle="Using .vuh files for pretty urls"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial-advanced" upLabel="Up"> 
		