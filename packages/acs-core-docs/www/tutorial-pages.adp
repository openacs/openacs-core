
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Creating Web Pages}</property>
<property name="doc(title)">Creating Web Pages</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-database" leftLabel="Prev"
		    title="
Chapter 9. Development Tutorial"
		    rightLink="tutorial-debug" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-pages" id="tutorial-pages"></a>Creating Web Pages</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel Aufrecht</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140592102536376" id="idp140592102536376"></a>Install some API</h3></div></div></div><p>As a workaround for missing content-repository functionality,
copy a provided file into the directory for Tcl files:</p><pre class="screen"><span class="action"><span class="action">cp /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/acs-core-docs/www/files/tutorial/note-procs.tcl /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/tcl/</span></span></pre><p>To make this file take effect, go to the <a class="ulink" href="/acs-admin/apm" target="_top">APM</a> and choose "Reload
changed" for "MyFirstPackage".</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140592102540216" id="idp140592102540216"></a>Page Map</h3></div></div></div><p>Our package will have two visible pages. The first shows a list
of all objects; the second shows a single object in view or edit
mode, and can also be used to add an object. The index page will
display the list, but since we might reuse the list later,
we&#39;ll put it in a separate file and include it on the index
page.</p><div class="figure">
<a name="idp140592102541576" id="idp140592102541576"></a><p class="title"><strong>Figure 9.5. Page
Map</strong></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/tutorial-page-map.png" align="middle" alt="Page Map"></div></div>
</div><br class="figure-break">
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140592107977784" id="idp140592107977784"></a>Build the "Index" page</h3></div></div></div><p>Each user-visible page in your package has, typically, three
parts. The <code class="computeroutput">tcl</code> file holds the
procedural logic for the page, including Tcl and
database-independent SQL code, and does things like check
permissions, invoke the database queries, and modify variables, and
the <code class="computeroutput">adp</code> page holds html. The
<code class="computeroutput">-postgres.xql</code> and <code class="computeroutput">-oracle.xql</code> files contains
database-specific SQL. The default page in any directory is
<code class="computeroutput">index</code>, so we&#39;ll build that
first, starting with the Tcl file:</p><pre class="screen">
[$OPENACS_SERVICE_NAME postgresql]$<strong class="userinput"><code> cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackages/www</code></strong>
[$OPENACS_SERVICE_NAME www]$ <strong class="userinput"><code>emacs index.tcl</code></strong>
</pre><p>Paste this into the file.</p><pre class="programlisting">
ad_page_contract {
    This is the main page for the package.  It displays all of the Notes and provides links to edit them and to create new Notes.

    \@author Your Name (you\@example.com)
    \@cvs-id $&zwnj;Id: index.tcl,v 1.2.22.1 2015/09/10 08:21:20 gustafn Exp $
}

set page_title [ad_conn instance_name]
set context [list]
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
</pre><p>Now <code class="computeroutput">index.adp</code>:</p><pre class="programlisting">
&lt;master&gt;
  &lt;property name="doc(title)"&gt;\@page_title;literal\@&lt;/property&gt;
  &lt;property name="context"&gt;\@context;literal\@&lt;/property&gt;
&lt;include src="/packages/myfirstpackage/lib/note-list"&gt;
</pre><p>The index page includes the list page, which we put in /lib
instead of /www to designate that it&#39;s available for reuse by
other packages.</p><pre class="screen">
[$OPENACS_SERVICE_NAME www]$<strong class="userinput"><code> mkdir /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/lib</code></strong>
[$OPENACS_SERVICE_NAME www]$<strong class="userinput"><code> cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/lib</code></strong>
[$OPENACS_SERVICE_NAME lib]$ <strong class="userinput"><code>emacs note-list.tcl</code></strong>
</pre><pre class="programlisting">
template::list::create \
    -name notes \
    -multirow notes \
    -actions { "Add a Note" note-edit} \
    -elements {
        edit {
            link_url_col edit_url
            display_template {
                &lt;img src="/resources/acs-subsite/Edit16.gif" width="16" height="16" border="0"&gt;
            }
            sub_class narrow
        }
        title {
            label "Title"
        }
        delete {
            link_url_col delete_url 
            display_template {
                &lt;img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" border="0"&gt;
            }
            sub_class narrow
        }
    }

db_multirow \
    -extend {
        edit_url
        delete_url
    } notes notes_select {
        select ci.item_id,
               n.title
        from   cr_items ci,
               mfp_notesx n
        where  n.revision_id = ci.live_revision
    } {
        set edit_url [export_vars -base "note-edit" {item_id}]
        set delete_url [export_vars -base "note-delete" {item_id}]
    }
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
</pre><pre class="screen">
[$OPENACS_SERVICE_NAME lib]$ <strong class="userinput"><code>emacs note-list.adp</code></strong>
</pre><pre class="programlisting">
&lt;listtemplate name="notes"&gt;&lt;/listtemplate&gt;
</pre><p>You can test your work by viewing the page /myfirstpackage on
your installation.</p><p>Create the add/edit page. If note_id is passed in, it display
that note, and can change to edit mode if appropriate. Otherwise,
it presents a form for adding notes.</p><pre class="screen">
[$OPENACS_SERVICE_NAME lib]$<strong class="userinput"><code> cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/www</code></strong>
[$OPENACS_SERVICE_NAME www]$ <strong class="userinput"><code>emacs note-edit.tcl</code></strong>
</pre><pre class="programlisting">
ad_page_contract {
    This is the view-edit page for notes.

    \@author Your Name (you\@example.com)
    \@cvs-id $&zwnj;Id: note-edit.tcl,v 1.3.2.1 2015/09/10 08:21:20 gustafn Exp $
 
    \@param item_id If present, assume we are editing that note.  Otherwise, we are creating a new note.
} {
    item_id:naturalnum,optional
}

ad_form -name note -form {
    {item_id:key}
    {title:text {label Title}}
} -new_request {
    auth::require_login
    permission::require_permission -object_id [ad_conn package_id] -privilege create
    set page_title "Add a Note"
    set context [list $page_title]
} -edit_request {
    auth::require_login
    permission::require_write_permission -object_id $item_id
    mfp::note::get \
        -item_id $item_id \
        -array note_array 

    set title $note_array(title)

    set page_title "Edit a Note"
    set context [list $page_title]
} -new_data {
    mfp::note::add \
        -title $title
} -edit_data {
    mfp::note::edit \
        -item_id $item_id \
        -title $title
} -after_submit {
    ad_returnredirect "."
    ad_script_abort
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
</pre><pre class="screen">
[$OPENACS_SERVICE_NAME www]$ <strong class="userinput"><code>emacs note-edit.adp</code></strong>
</pre><pre class="programlisting">
&lt;master&gt;
  &lt;property name="doc(title)"&gt;\@page_title;literal\@&lt;/property&gt;
  &lt;property name="context"&gt;\@context;literal\@&lt;/property&gt;
  &lt;property name="focus"&gt;note.title&lt;/property&gt;
  
&lt;formtemplate id="note"&gt;&lt;/formtemplate&gt;
</pre><p>And the delete page. Since it has no UI, there is only a Tcl
page, and no adp page.</p><pre class="screen">
[$OPENACS_SERVICE_NAME www]$ <strong class="userinput"><code>emacs note-delete.tcl</code></strong>
</pre><pre class="programlisting">
ad_page_contract {
    This deletes a note

    \@author Your Name (you\@example.com)
    \@cvs-id $&zwnj;Id: note-delete.tcl,v 1.3.2.1 2015/09/10 08:21:20 gustafn Exp $
 
    \@param item_id The item_id of the note to delete
} {
    item_id:integer
}

permission::require_write_permission -object_id $item_id
set title [content::item::get_title -item_id $item_id]
mfp::note::delete -item_id $item_id

ad_returnredirect "."
# stop running this code, since we&#39;re redirecting
abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
</pre>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-database" leftLabel="Prev" leftTitle="Setting Up Database Objects"
		    rightLink="tutorial-debug" rightLabel="Next" rightTitle="Debugging and Automated Testing"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial" upLabel="Up"> 
		