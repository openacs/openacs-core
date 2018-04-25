
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Adding Comments}</property>
<property name="doc(title)">Adding Comments</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="tutorial-etp-templates" leftLabel="Prev"
			title="Chapter 10. Advanced
Topics"
			rightLink="tutorial-admin-pages" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-comments" id="tutorial-comments"></a>Adding Comments</h2></div></div></div><p>You can track comments for any ACS Object. Here we&#39;ll track
comments for notes. On the note-edit.tcl/adp pair, which is used to
display individual notes, we want to put a link to add comments at
the bottom of the screen. If there are any comments, we want to
show them.</p><p>First, we need to generate a url for adding comments. In
note-edit.tcl:</p><pre class="programlisting">
 set comment_add_url [export_vars -base [general_comments_package_url]comment-add {
  { object_id $note_id } 
  { object_name $title } 
  { return_url "[ad_conn url]?[ad_conn query]"} 
 }]
 </pre><p>This calls a global, public Tcl function that the
general_comments package registered, to get its url. You then embed
in that url the id of the note and its title, and set the
return_url to the current url so that the user can return after
adding a comment.</p><p>We need to create html that shows any existing comments. We do
this with another general_comments function:</p><pre class="programlisting">
set comments_html [general_comments_get_comments
     -print_content_p 1 $note_id]</pre><p>First, we pass in an optional parameter that says to actually
show the contents of the comments, instead of just the fact that
there are comments. Then you pass the note id, which is also the
acs_object id.</p><p>We put our two new variables in the note-edit.adp page.</p><pre class="programlisting">
&lt;a href="\@comment_add_url\@"&gt;Add a comment&lt;/a&gt;
 \@comments_html\@</pre>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="tutorial-etp-templates" leftLabel="Prev" leftTitle="OpenACS Edit This Page Templates"
			rightLink="tutorial-admin-pages" rightLabel="Next" rightTitle="Admin Pages"
			homeLink="index" homeLabel="Home" 
			upLink="tutorial-advanced" upLabel="Up"> 
		    