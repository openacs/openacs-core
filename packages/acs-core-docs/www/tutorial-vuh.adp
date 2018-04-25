
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Using .vuh files for pretty urls}</property>
<property name="doc(title)">Using .vuh files for pretty urls</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="tutorial-hierarchical" leftLabel="Prev"
			title="Chapter 10. Advanced
Topics"
			rightLink="tutorial-css-layout" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-vuh" id="tutorial-vuh"></a>Using .vuh files for pretty urls</h2></div></div></div><p>.Vuh files are special cases of .tcl files, used for rewriting
incoming urls. We can use a vuh file to prettify the uri for our
notes. Instead of <code class="computeroutput">note-edit?item_id=495</code>, we can use
<code class="computeroutput">note/495</code>. To do this, we will
need a new .vuh file for redirection and we will need to change the
referring links in note-list. First, add the vuh:</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/packages/myfirstpackage/www</code></strong>
[$OPENACS_SERVICE_NAME www]$ <strong class="userinput"><code>emacs note.vuh</code></strong>
</pre><p>Paste this into the file:</p><pre class="programlisting"># Transform requests of type: a/b
# into this internal request: A?c=b
# for example, note/495 &gt; note-edit?item_id=496
# a: base name of this .vuh file
# b: from the request
# A: hard-coded
# C: hard-coded

set query [ad_conn url]

set request [string range $query [string last / $query]+1 end]

rp_form_put item_id $request

set internal_path "/packages/[ad_conn package_key]/www/note-edit"

rp_internal_redirect $internal_path

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
</pre><p>We parse the incoming request and treat everything after the
final / as the item id. Note that this simple redirection will lose
any additional query parameters passed in. Many OpenACS objects
maintain a pretty-name, which is a unique, human-readable string,
usually derived from title, which makes an even better 'pretty
url' than a numeric id; this requires that your display page be
able to look up an item based on pretty id.</p><p>We use <code class="computeroutput">rp_form_put</code> to store
the item id in the internal register that the next page is
expecting, and then redirects the request in process internally
(ie, without a browser refresh).</p><p>Next, modify note-list so that its link is of the new form.:</p><pre class="screen">[$OPENACS_SERVICE_NAME www]$ <strong class="userinput"><code>emacs ../lib/note-edit.tcl</code></strong>
</pre><pre class="programlisting">
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
        <span class="strong"><strong>set edit_url [export_vars -base "note/$item_id"]</strong></span>
        set delete_url [export_vars -base "note-delete" {item_id}]
    }
</pre><p>You may also need to change some of the links in your package.
Commonly, you would use ad_conn package_url to build the URL.
Otherwise, some of your links may be relative to the virtual
directory (note/) instead of the actual directory that the note is
being served from.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="tutorial-hierarchical" leftLabel="Prev" leftTitle="Hierarchical data"
			rightLink="tutorial-css-layout" rightLabel="Next" rightTitle="Laying out a page with CSS instead of
tables"
			homeLink="index" homeLabel="Home" 
			upLink="tutorial-advanced" upLabel="Up"> 
		    