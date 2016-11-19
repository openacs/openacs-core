
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Admin Pages}</property>
<property name="doc(title)">Admin Pages</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-comments" leftLabel="Prev"
		    title="
Chapter 10. Advanced Topics"
		    rightLink="tutorial-categories" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-admin-pages" id="tutorial-admin-pages"></a>Admin
Pages</h2></div></div></div><p>There are at least two flavors of admin user interface:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Admins use same pages as all other users, except that they are
offered admin links and buttons where appropriate. For example, if
admins have privilege to bulk-delete items you could provide
checkboxes next to every item seen on a list and the Delete
Selected button on the bottom of the list.</p></li><li class="listitem">
<p>Dedicated admin pages. If you want admins to have access to data
that users aren&#39;t interested in or aren&#39;t allowed to see
you will need dedicated admin pages. The conventional place to put
those dedicated admin pages is in the <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/www/admin</code>
directory.</p><pre class="screen">
[$OPENACS_SERVICE_NAME www]$ <strong class="userinput"><code>mkdir admin</code></strong>
</pre><pre class="screen">
[$OPENACS_SERVICE_NAME www]$ <strong class="userinput"><code>cd admin</code></strong>
</pre><p>Even if your application doesn&#39;t need any admin pages of its
own you will usually need at least one simple page with a bunch of
links to existing administration UI such as Category Management or
standard Parameters UI. Adding the link to Category Management is
described in the section on categories. The listing below adds a
link to the Parameters UI of our package.</p><pre class="screen">
[$OPENACS_SERVICE_NAME admin]$ <strong class="userinput"><code>vi index.adp</code></strong>
</pre><pre class="programlisting">
&lt;master&gt;
&lt;property name="title"&gt;\@title;noquote\@&lt;/property&gt;
&lt;property name="context"&gt;\@context;noquote\@&lt;/property&gt;

&lt;ul class="action-links"&gt;
  &lt;li&gt;&lt;a href="\@parameters_url\@" title="Set parameters" class="action_link"&gt;Set parameters&lt;/a&gt;&lt;/li&gt;
&lt;/ul&gt;
</pre><pre class="screen">
[$OPENACS_SERVICE_NAME admin]$ <strong class="userinput"><code>vi index.tcl</code></strong>
</pre><pre class="programlisting">
ad_page_contract {} {
} -properties {
    context_bar
}

set package_id [ad_conn package_id]

permission::require_permission \
          -object_id $package_id \
          -privilege admin]

set context [list]

set title "Administration"

set parameters_url [export_vars -base "/shared/parameters" {
  package_id { return_url [ad_return_url] }
}]

</pre><p>Now that you have the first admin page it would be nice to have
a link to it somewhere in the system so that admins don&#39;t have
to type in the <code class="computeroutput">/admin</code> every
time they need to reach it. You could put a static link to the
toplevel <code class="computeroutput">index.adp</code> but that
might be distracting for people who are not admins. Besides, some
people consider it impolite to first offer a link and then display
a nasty "You don&#39;t have permission to access this
page" message.</p><p>In order to display the link to the admin page only to users
that have admin privileges add the following code near the top of
<code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/www/admin/index.tcl</code>:</p><pre class="programlisting">

set package_id [ad_conn package_id]

set admin_p [permission::permission_p -object_id $package_id \
  -privilege admin -party_id [ad_conn untrusted_user_id]]

if { $admin_p } {
    set admin_url "admin"
    set admin_title Administration
}
</pre><p>In <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/www/admin/index.adp</code>
put:</p><pre class="programlisting">
&lt;if \@admin_p\@ ne nil&gt;
  &lt;a href="\@admin_url\@"&gt;\@admin_title\@&lt;/a&gt;
&lt;/if&gt;
</pre>
</li>
</ul></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-comments" leftLabel="Prev" leftTitle="Adding Comments"
		    rightLink="tutorial-categories" rightLabel="Next" rightTitle="Categories"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial-advanced" upLabel="Up"> 
		