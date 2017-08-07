
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Categories}</property>
<property name="doc(title)">Categories</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-admin-pages" leftLabel="Prev"
		    title="
Chapter 10. Advanced Topics"
		    rightLink="profile-code" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-categories" id="tutorial-categories"></a>Categories</h2></div></div></div><div class="authorblurb">
<p>extended by <a class="ulink" href="mailto:nima.mazloumi\@gmx.de" target="_top">Nima Mazloumi</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>You can associate any ACS Object with one or more categories. In
this tutorial we&#39;ll show how to equip your application with
user interface to take advantage of the Categories service.</p><p>We&#39;ll start by installing the Categories service. Go to
<code class="computeroutput">/acs/admin</code> and install it. This
step won&#39;t be necessary for the users of your applications
because you&#39;ll create a dependency with the Package Manager
which will take care that the Categories service always gets
installed when your application gets installed.</p><p>Now that we have installed the Categories service we can proceed
to modifying our application so that it can take advantage of it.
We&#39;ll do it in three steps:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>The Categories service provides a mechanism to associate one or
more <span class="emphasis"><em>category trees</em></span> that are
relevant to your application. One example of such tree is a tree of
geographical locations. Continents are on the top of such tree,
each continent containing countries etc. Another tree might contain
market segments etc. Before users of your application can take
advantage of the Categories service there needs to be a way for
administrators of your application to choose which category trees
are applicable for the application.</p><p>The way to achieve this is is to provide a link to the Category
Management pages. Add the following snippet to your <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/www/admin/index.tcl</code>
file:</p><pre class="programlisting">
                  set category_map_url [export_vars -base "[site_node::get_package_url -package_key categories]cadmin/one-object" { { object_id $package_id } }]
          
</pre><p>and the following snippet to your <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/www/admin/index.adp</code>
file:</p><pre class="programlisting">
                  &lt;a href="\@category_map_url\@"&gt;#­categories.Site_wide_Categories#&lt;/a&gt;
          
</pre><p>The link created by the above code (<code class="computeroutput">category_map_url</code>) will take the admin to
the generic admin UI where he can pick category trees that make
sense for this application. The same UI also includes facilities to
build and edit category trees. Notice that the only parameter in
this example is <code class="computeroutput">package_id</code> so
that category trees will be associated with the object identified
by this <code class="computeroutput">package_id</code>. The
categorization service is actually more general than that: instead
of <code class="computeroutput">package_id</code> you could use an
ID of some other object that serves as a "container" in
your application. For example, if your discussion forums
application supports multiple forums you would use <code class="computeroutput">forum_id</code> to associate category trees with
just that one forum rather than the entire application
instance.</p>
</li><li class="listitem">
<p>Once the category trees have been selected users need a way to
categorize items. The easiest way to do this is by adding the
<code class="computeroutput">category</code> widget type of the
form builder to <code class="computeroutput">note-edit.tcl</code>.
To achieve this we&#39;ll need to use the <code class="computeroutput">-extend</code> switch to the <code class="computeroutput">ad_form</code> command. Here&#39;s the
"meat" of the <code class="computeroutput">note-edit.tcl</code> page:</p><pre class="programlisting">
                        # extend the form to support categories
                        set package_id [ad_conn package_id]
                            
                        category::ad_form::add_widgets -form_name note -container_object_id $package_id -categorized_object_id [value_if_exists item_id]

                        ad_form -extend -name note -on_submit {
                                set category_ids [category::ad_form::get_categories -container_object_id $package_id]
                        } -new_data {
                                ....
                                        category::map_object -remove_old -object_id $item_id $category_ids
                        db_dml insert_asc_named_object "insert into acs_named_objects (object_id, object_name, package_id) values ( :item_id, :title, :package_id)"
                        } -edit_data {
                        ....
                                db_dml update_asc_named_object "update acs_named_objects set object_name = :title, package_id = :package_id where object_id = :item_id"
                                category::map_object -remove_old -object_id $item_id $category_ids
                        } -after_submit {
                                        ad_returnredirect "."
                                        ad_script_abort
                        }
                        
</pre><p>While the <code class="computeroutput">category::ad_form::add_widgets</code> proc is
taking care to extend your form with associated categories you need
to ensure that your items are mapped to the corresponding category
object yourself. Also since the categories package knows nothing
from your objects you have to keep the <code class="computeroutput">acs_named_objects</code> table updated with any
changes taking place. We use the items title so that they are
listed in the categories browser by title.</p><p>Make sure that you also delete these entries if your item is
delete. Add this to your corresponding delete page:</p><pre class="programlisting">
                        db_dml delete_named_object "delete from acs_named_objects where object_id = :item_id"
                        
</pre><p>
<code class="computeroutput">note-edit.tcl</code> requires a
<code class="computeroutput">note_id</code> to determine which
record should be deleted. It also looks for a confirmation
variable, which should initially be absert. If it is absent, we
create a form to allow the user to confirm the deletion. Note that
in <code class="computeroutput">entry-edit.tcl</code> we used
<code class="computeroutput">ad_form</code> to access the Form
Template commands; here, we call them directly because we don&#39;t
need the extra features of ad_form. The form calls itself, but with
hidden variables carrying both <code class="computeroutput">note_id</code> and <code class="computeroutput">confirm_p</code>. If confirm_p is present, we
delete the record, set redirection back to the index, and abort
script execution.</p><p>The database commands:</p><pre class="screen">
[$OPENACS_SERVICE_NAME\@yourserver www]$ <strong class="userinput"><code>emacs note-delete.xql</code></strong>
</pre><pre class="programlisting">
&lt;?xml version="1.0"?&gt;
&lt;queryset&gt;
  &lt;fullquery name="do_delete"&gt;
    &lt;querytext&gt;
      select samplenote__delete(:note_id)
    &lt;/querytext&gt;
  &lt;/fullquery&gt;
  &lt;fullquery name="get_name"&gt;
    &lt;querytext&gt;
      select samplenote__name(:note_id)
    &lt;/querytext&gt;
  &lt;/fullquery&gt;
&lt;/queryset&gt;
</pre><p>And the adp page:</p><pre class="screen">
[$OPENACS_SERVICE_NAME\@yourserver www]$ <strong class="userinput"><code>emacs note-delete.adp</code></strong>
</pre><pre class="programlisting">
&lt;master&gt;
&lt;property name="title"&gt;\@title\@&lt;/property&gt;
&lt;property name="context"&gt;{\@title\@}&lt;/property&gt;
&lt;h2&gt;\@title\@&lt;/h2&gt;
&lt;formtemplate id="note-del-confirm"&gt;&lt;/formtemplate&gt;
&lt;/form&gt;
</pre><p>The ADP is very simple. The <code class="computeroutput">formtemplate</code> tag outputs the HTML form
generated by the ad_form command with the matching name. Test it by
adding the new files in the APM and then deleting a few
samplenotes.</p>
</li><li class="listitem">
<p>We will now make categories optional on package instance level
and also add a configuration page to allow the package admin to
enable/disable categories for his package.</p><p>Go to the APM and create a number parameter with the name
"<code class="computeroutput">EnableCategoriesP</code>"
and the default value "<code class="computeroutput">0</code>".</p><p>Add the following lines to your <code class="computeroutput">index.tcl</code>:</p><pre class="programlisting">
          set return_url [ns_conn url]
          set use_categories_p [parameter::get -parameter "EnableCategoriesP"]
          
</pre><p>Change your to this:</p><pre class="programlisting">
                        &lt;a href=configure?&lt;%=[export_vars -url {return_url}]%&gt;&gt;Configure&lt;/a&gt;
                        &lt;if \@use_categories_p\@&gt;
                        &lt;a href="\@category_map_url\@"&gt;#­categories.Site_wide_Categories#&lt;/a&gt;
                        &lt;/if&gt;
          
</pre><p>Now create a configure page</p><pre class="programlisting">
                ad_page_contract {
                        This page allows an admin to change the categories usage mode.
                        } {
                        {return_url ""}
                        }

                        set title "Configure category mode"
                        set context [list $title]
                        set use_categories_p [parameter::get -parameter "EnableCategoriesP"]

                        ad_form -name categories_mode -form {
                        {enabled_p:text(radio)
                                {label "Enable Categories"}
                                {options {{Yes 1} {No 0}}}
                                {value $use_categories_p}
                        }
                        {return_url:text(hidden) {value $return_url}}
                        {submit:text(submit) {label "Set Mode"}}
                        } -on_submit {
                        parameter::set_value  -parameter "EnableCategoriesP" -value $enabled_p
                        if {$return_url ne ""} {
                                ns_returnredirect $return_url
                        }
                        }
           
</pre><p>and add this to its corresponding ADP page</p><pre class="programlisting">
                &lt;master&gt;
                        &lt;property name="title"&gt;\@title\@&lt;/property&gt;
                        &lt;property name="context"&gt;\@context\@&lt;/property&gt;

                        &lt;formtemplate id="categories_mode"&gt;&lt;/formtemplate&gt;
              
</pre><p>Reference this page from your admin page</p><pre class="programlisting">
                #TCL:
                set return_url [ad_conn url]

                #ADP:
                &lt;a href=configure?&lt;%=[export_vars -url {return_url}]%&gt;&gt;Configure&lt;/a&gt;
                
</pre><p>Change the <code class="computeroutput">note-edit.tcl</code>:</p><pre class="programlisting">
                # Use Categories?
                set use_categories_p [parameter::get -parameter "EnableCategoriesP" -default 0]
                if { $use_categories_p == 1 } {
                        # YOUR NEW FORM DEFINITION
                } else {
                # YOUR OLD FORM DEFINITION
                }
        
</pre>
</li><li class="listitem">
<p>You can filter your notes using categories. The below example
does not support multiple filters and displays a category in a flat
format.</p><p>The first step is to define the optional parameter <code class="computeroutput">category_id</code> for <code class="computeroutput">index.tcl</code>:</p><pre class="programlisting">
                ad_page_contract {
                YOUR TEXT
                } {
                        YOURPARAMS
                {category_id:integer,optional {}}
                }
          
</pre><p>Now you have to check whether categories are enabled or not. If
this is the case and a category id is passed you need to extend
your sql select query to support filtering. One way would be to
extend the <code class="computeroutput">mfp::note::get</code> proc
to support two more swiches <code class="computeroutput">-where_clause</code> and <code class="computeroutput">-from_clause</code>.</p><pre class="programlisting">
                set use_categories_p [parameter::get -parameter "EnableCategoriesP" -default 0]

                if { $use_categories_p == 1 &amp;&amp; $category_id ne "" } {

                        set from_clause "category_object_map com, acs_named_objects nam"
                        set_where_clause "com.object_id = qa.entry_id and
                                                                nam.package_id = :package_id and
                                                                com.object_id = nam.object_id and
                                                                com.category_id = :category_id"
                        
                        ...
                                                                
                mfp::note::get \
                -item_id $item_id \
                -array note_array \
                -where_clause $where_clause \
                -from_clause $from_clause
                
                ...
                } else {
                # OLD STUFF
                }
          
</pre><p>Also you need to make sure that the user can see the
corresponding categories. Add the following snippet to the end of
your index page:</p><pre class="programlisting">
          # Site-Wide Categories
                if { $use_categories_p == 1} {
                set package_url [ad_conn package_url]
                if { $category_id ne "" } {
                        set category_name [category::get_name $category_id]
                        if { $category_name eq "" } {
                        ad_return_exception_page 404 "No such category" "Site-wide \
                                Category with ID $category_id doesn&#39;t exist"
                        return
                        }
                        # Show Category in context bar
                        append context_base_url /cat/$category_id
                        lappend context [list $context_base_url $category_name]
                        set type "all"
                }

                # Cut the URL off the last item in the context bar
                if { [llength $context] &gt; 0 } {
                        set context [lreplace $context end end [lindex $context end end]]
                }

                db_multirow -unclobber -extend { category_name tree_name } categories categories {
                        select c.category_id as category_id, c.tree_id
                        from   categories c, category_tree_map ctm
                        where  ctm.tree_id = c.tree_id
                        and    ctm.object_id = :package_id
                } {
                        set category_name [category::get_name $category_id]
                        set tree_name [category_tree::get_name $tree_id]
                }
                }
                
</pre><p>and to the corresponding index ADP page:</p><pre class="programlisting">
                &lt;if \@use_categories_p\@&gt;
                        &lt;multiple name="categories"&gt;
                        &lt;h2&gt;\@categories.tree_name\@
                        &lt;group column="tree_id"&gt;
                        &lt;a href="\@package_url\@cat/\@categories.category_id\@?\@YOURPARAMS\@&amp;category_id=\@categories.category_id\@"&gt;\@categories.category_name\@
                        &lt;/group&gt;
                &lt;/multiple&gt;
                &lt;a href="\@package_url\@view?\@YOURPARAMS\@"&gt;All Items&lt;/if&gt;
          
</pre><p>Finally you need a an <code class="computeroutput">index.vuh</code> in your www folder to rewrite the
URLs correctly, <a class="xref" href="tutorial-vuh" title="Using .vuh files for pretty urls">the section called
&ldquo;Using .vuh files for pretty
urls&rdquo;</a>:</p><pre class="programlisting">
          set url /[ad_conn extra_url]

          if {[regexp {^/+cat/+([^/]+)/*} $url ignore_whole category_id]} {
              rp_form_put category_id $category_id
          }
          rp_internal_redirect "/packages/YOURPACKAGE/www/index"          
          
</pre><p>Now when ever the user select a category only notes that belong
to this category are displayed.</p>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-admin-pages" leftLabel="Prev" leftTitle="Admin Pages"
		    rightLink="profile-code" rightLabel="Next" rightTitle="Profile your code"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial-advanced" upLabel="Up"> 
		