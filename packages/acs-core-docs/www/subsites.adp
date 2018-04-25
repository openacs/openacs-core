
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Writing OpenACS Application Pages}</property>
<property name="doc(title)">Writing OpenACS Application Pages</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="permissions" leftLabel="Prev"
			title="Chapter 11. Development
Reference"
			rightLink="parties" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="subsites" id="subsites"></a>Writing OpenACS Application Pages</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By Rafael H. Schloming and Pete
Su</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-overview" id="subsites-overview"></a>Overview</h3></div></div></div><p>In this document, we&#39;ll examine the user interface pages of
the Notes application in more detail, covering two separate aspects
of page development in OpenACS. First, we&#39;ll talk about the
code needed to make your pages aware of which application instance
they are running in. Second, we&#39;ll talk about using the form
builder to develop form-based user interfaces in OpenACS. While
these seem like unrelated topics, they both come up in the example
page that we are going to look at, so it makes sense to address
them at the same time.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-instances" id="subsites-instances"></a>Application Instances and Subsites</h3></div></div></div><p>As you will recall from the <a class="link" href="packages" title="OpenACS Packages">packages</a> tutorial, the Request
Processor (RP) and Package Manager (APM) allow site administrators
to define an arbitrary mapping from URLs in the site to objects
representing content. These objects may represent single files, or
entire applications. The APM uses the site map to map application
instances to particular URLs within a site. We call creating such a
mapping <span class="emphasis"><em>mounting</em></span> the
application instance at a particular URL. The tutorial also showed
how a given URL is translated into a physical file to serve using
the site map. We&#39;ll repeat this description here, assuming that
you have mounted an instance of Notes at the URL <code class="computeroutput">/notes</code> as we did in the <a class="link" href="packages" title="What a Package Looks Like">packages-example</a>:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>AOLserver receives your request for the URL <code class="computeroutput">/notes/somepage</code>.</p></li><li class="listitem"><p>This URL is passed to the request processor.</p></li><li class="listitem"><p>The RP looks up the URL in the site map, and sees that the
object mounted at that location is an instance of the <code class="computeroutput">notes</code> application.</p></li><li class="listitem"><p>The RP asks the package manager where in the file system the
Notes package lives. In the standard case, this would be
<code class="computeroutput">ROOT/packages/notes</code>.</p></li><li class="listitem"><p>The RP translates the URL to serve a page relative to the page
root of the application, which is <code class="computeroutput">ROOT/packages/notes/www/</code>. Therefore, the
page that is finally served is <code class="computeroutput">ROOT/packages/notes/www/hello.html</code>, which
is what we wanted.</p></li>
</ul></div><p>What is missing from this description is a critical fact for
application developers: In addition to working out what file to
serve, the RP also stores information about which package instance
the file belongs to into the AOLserver connection environment. The
following <code class="computeroutput">ad_conn</code> interfaces
can be used to extract this information:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><code class="computeroutput">[ad_conn
package_url]</code></span></dt><dd><p>If the URL refers to a package instance, this is the URL to the
root of the tree where the package is mounted.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
package_id]</code></span></dt><dd><p>If the URL refers to a package instance, this is the ID of that
package instance.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
package_key]</code></span></dt><dd><p>If the URL refers to a package instance, this is the unique key
name of the package.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
extra_url]</code></span></dt><dd><p>If we found the URL in the site map, this is the tail of the URL
following the part that matched a site map entry.</p></dd>
</dl></div><p>In the Notes example, we are particularly interested in the
<code class="computeroutput">package_id</code> field. If you study
the data model and code, you&#39;ll see why. As we said before in
the <a class="link" href="objects" title="OpenACS Data Models and the Object System">data modeling</a>
tutorial, the Notes application points the <code class="computeroutput">context_id</code> of each Note object that it
creates to the package instance that created it. That is, the
<code class="computeroutput">context_id</code> corresponds exactly
to the <code class="computeroutput">package_id</code> that comes in
from the RP. This is convenient because it allows the administrator
and the owner of the package to easily define access control
policies for all the notes in a particular instance just my setting
permissions on the package instance itself.</p><p>The code for adding and editing notes, in <code class="computeroutput">notes/www/add-edit.tcl</code>, shows how this
works. At the top of the page, we extract the <code class="computeroutput">package_id</code> and use it to do permission
checks:</p><pre class="programlisting">

set package_id [ad_conn package_id]

if {[info exists note_id]} {
      permission::require_permission -object_id $note_id -privilege write

      set context_bar [ad_context_bar "Edit Note"]
} else {
      permission::require_permission -object_id $note_id -privilege create

      set context_bar [ad_context_bar "New Note"]
}

</pre><p>This code figures out whether we are editing an existing note or
creating a new one. It then ensures that we have the right
privileges for each action.</p><p>Later, when we actually create a note, the SQL that we run
ensures that the <code class="computeroutput">context_id</code> is
set the right way:</p><pre class="programlisting">

db_dml new_note {
  declare
    id integer;
  begin
    id := note.new(
      owner_id =&gt; :user_id,
      title =&gt; :title,
      body =&gt; :body,
      creation_user =&gt; :user_id,
      creation_ip =&gt; :peeraddr,
      context_id =&gt; :package_id
    );
  end;
}

</pre><p>The rest of this page makes calls to the form builder part of
the template system. This API allows you to write forms-based pages
without generating a lot of duplicated HTML in your pages. It also
encapsulates most of the common logic that we use in dealing with
forms, which we&#39;ll discuss next.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-using-forms" id="subsites-using-forms"></a>Using Forms</h3></div></div></div><p>The forms API is pretty simple: You use calls in the
<code class="computeroutput">template::form</code> namespace in
your Tcl script to create form elements. The final template page
then picks this stuff up and lays the form out for the user. The
form is set up to route submit buttons and whatnot back to the same
Tcl script that set up the form, so your Tcl script will also
contain the logic needed to process these requests.</p><p>So, given this outline, here is a breakdown of how the forms
code works in the <code class="computeroutput">add-edit.tcl</code>
page. First, we create a form object called <code class="computeroutput">new_note</code>:</p><pre class="programlisting">

template::form create new_note

</pre><p>All the forms related code in this page will refer back to this
object. In addition, the <code class="computeroutput">adp</code>
part of this page does nothing but display the form object:</p><pre class="programlisting">

&lt;master&gt;

\@context_bar\@

&lt;hr&gt;

&lt;center&gt;
&lt;formtemplate id="new_note"&gt;&lt;/formtemplate&gt;
&lt;/center&gt;

</pre><p>The next thing that the Tcl page does is populate the form with
form elements. This code comes first:</p><pre class="programlisting">

if {[template::form is_request new_note] &amp;&amp; [info exists note_id]} {

  template::element create new_note note_id \
      -widget hidden \
      -datatype number \
      -value $note_id

  db_1row note_select {
    select title, body
    from notes
    where note_id = :note_id
  }
}

</pre><p>The <code class="computeroutput">if_request</code> call returns
true if we are asking the page to render the form for the first
time. That is, we are rendering the form to ask the user for input.
The <code class="computeroutput">tcl</code> part of a form page can
be called in 3 different states: the initial request, the initial
submission, and the validated submission. These states reflect the
typical logic of a forms based page in OpenACS:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>First render the input form.</p></li><li class="listitem"><p>Next, control passes to a validation page that checks and
confirms the inputs.</p></li><li class="listitem"><p>Finally, control passes to the page that performs the update in
the database.</p></li>
</ul></div><p>The rest of the <code class="computeroutput">if</code> condition
figures out if we are creating a new note or editing an existing
note. If <code class="computeroutput">note_id</code> is passed to
us from the calling page, we assume that we are editing an existing
note. In this case, we do a database query to grab the data for the
note so we can populate the form with it.</p><p>The next two calls create form elements where the user can
insert or edit the title and body of the Note. The interface to
<code class="computeroutput">template::element</code> is pretty
straightforward.</p><p>Finally, the code at the bottom of the page performs the actual
database updates when the form is submitted and validated:</p><pre class="programlisting">

if {[template::form is_valid new_note]} {
  set user_id [ad_conn user_id]
  set peeraddr [ad_conn peeraddr]

  if {[info exists note_id]} {
    db_dml note_update {
      update notes
      set title = :title,
          body = :body
      where note_id = :note_id
    }
  } else {
    db_dml new_note {
      declare
        id integer;
      begin
        id := note.new(
          owner_id =&gt; :user_id,
          title =&gt; :title,
          body =&gt; :body,
          creation_user =&gt; :user_id,
          creation_ip =&gt; :peeraddr,
          context_id =&gt; :package_id
        );
      end;
    }
  }

  ad_returnredirect "."
}

</pre><p>In this simple example, we don&#39;t do any custom validation.
The nice thing about using this API is that the forms library
handles all of the HTML rendering, input validation and database
transaction logic on your behalf. This means that you can write
pages without duplicating all of that code in every set of pages
that uses forms.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-how-it-all-fits" id="subsites-how-it-all-fits"></a>How it All Fits</h3></div></div></div><p>To watch all of this work, use the installer to update the Notes
package with the new code that you grabbed out of CVS or the
package repository, mount an instance of Notes somewhere in your
server and then try out the user interface pages. It should become
clear that in a real site, you would be able to, say, create a
custom instance of Notes for every registered user, mount that
instance at the user&#39;s home page, and set up the permissions so
that the instance is only visible to that user. The end result is a
site where users can come and write notes to themselves.</p><p>This is a good example of the leverage available in the OpenACS
5.9.0 system. The code that we have written for Notes is not at all
more complex than a similar application without access control or
site map awareness. By adding a small amount of code, we have taken
a small, simple, and special purpose application to something that
has the potential to be a very useful, general-purpose tool,
complete with multi-user features, access control, and centralized
administration.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-summary" id="subsites-summary"></a>Summary</h3></div></div></div><p>In OpenACS 5.9.0, application pages and scripts can be aware of
the package instance, or subsite in which they are executing. This
is a powerful general purpose mechanism that can be used to
structure web services in very flexible ways.</p><p>We saw how to use this mechanism in the Notes application and
how it makes it possible to easily turn Notes into an application
that appears to provide each user in a system with their own
private notes database.</p><p>We also saw how to use the templating system&#39;s forms API in
a simple way, to create forms based pages with minimal duplication
of code.</p><p><span class="cvstag">($&zwnj;Id: subsites.xml,v 1.10 2017/08/07
23:47:54 gustafn Exp $)</span></p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="permissions" leftLabel="Prev" leftTitle="Groups, Context, Permissions"
			rightLink="parties" rightLabel="Next" rightTitle="Parties in OpenACS"
			homeLink="index" homeLabel="Home" 
			upLink="dev-guide" upLabel="Up"> 
		    