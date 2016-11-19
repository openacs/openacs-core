
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Using Templates in OpenACS}</property>
<property name="doc(title)">Using Templates in OpenACS</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="db-api" leftLabel="Prev"
		    title="
Chapter 11. Development Reference"
		    rightLink="permissions" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="templates" id="templates"></a>Using Templates in OpenACS</h2></div></div></div><div class="authorblurb">
<p>By Pete Su</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="templates-overview" id="templates-overview"></a>Overview</h3></div></div></div><p>The OpenACS Template System (ATS) is designed to allow
developers to cleanly separate <span class="emphasis"><em>application logic</em></span> from <span class="emphasis"><em>display logic</em></span>. The intent is to have all
of the logic related to manipulating the database and other
application state data in one place, and all the logic related to
displaying the state of the application in another place. This
gives developer&#39;s quicker customization and easier upgrades,
and also allows developers and graphic designers to work more
independently.</p><p>In ATS, you write two files for every user-visible page in the
system. One is a plain <code class="computeroutput">.tcl</code>
file and the other is a special <code class="computeroutput">.adp</code> file. The <code class="computeroutput">.tcl</code> file runs a script that sets up a set
of name/value bindings that we call <span class="emphasis"><em>data
sources</em></span>. These <a class="ulink" href="/doc/acs-templating/guide/data" target="_top">data
sources</a> are generally the results of Tcl and/or database
queries or some combination thereof. The template system
automatically makes them available to the <code class="computeroutput">.adp</code> file, or the display part of the
template, which is written in a combination of HTML, special
template related tags, and data source substitutions.</p><p>In the overall context of our example OpenACS Notes application,
this document will show you how to set up a simple templated page
that displays a form to the user for entering new notes into the
system. In later sections of the DG, we&#39;ll discuss how to
develop the pages that actually add notes to the database, how to
provide a separate instance of the Notes application to every user
and how to design appropriate access control policies for the
system.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="templates-entering-notes" id="templates-entering-notes"></a>Entering Notes</h3></div></div></div><p>In order for the Notes application to be useful, we have to
allow users to enter data into the database. Typically, this takes
two pages: one that displays a form for data entry, and another
page that runs the code to update the database and tells the user
whether the operation failed. In this document, we will use the
template system to build the first of these pages. This isn&#39;t a
very interesting use of the system since we won&#39;t be displaying
much data, but we&#39;ll cover more on that end later.</p><p>The <code class="computeroutput">.tcl</code> file for the form
entry template is pretty simple. Here, the only thing we need from
the database is a new ID for the note object to be inserted. Open
up a file called <code class="computeroutput">note-add.tcl</code>
in the <code class="computeroutput">ROOT/packages/notes/www</code>
directory, and put the following code in it:</p><pre class="programlisting">

ad_page_contract {

    Form to add a note in OpenACS Notes.

    \@author Jane Coder 
    \@creation-date 11 Oct 2000

} -properties {
    note_id:onevalue
    submit_label:onevalue
    target:onevalue
    page_title:onevalue
} -query {
}

set user_id [ad_conn user_id]

db_1row user_name {
    select first_names || ' ' || last_name as user_name 
    from users
    where forum_id = :user_id
}

set page_title "Add a note for $user_name"
set submit_label "Add"
set target "note-add-2"
set note_id [db_nextval acs_object_id_seq]

ad_return_template "note-add"

</pre><p>Some things to note about this code:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The procedure <a class="link" href="tcl-doc" title="ad_page_contract">ad_page_contract</a> is always the first thing a
<code class="computeroutput">.tcl</code> file calls, if it&#39;s
under the www/ directory (i.e. not a Tcl library file). It does
validation of input values from the HTTP request (i.e. form
variables) and in this case, the <code class="computeroutput">-properties</code> clause is used to set up the
data sources that we will ship over to the <code class="computeroutput">.adp</code> part of the page. In this case, we
only use the simplest possible kind of data source, called a
<code class="computeroutput">onevalue</code>, which hold just a
single string value. Later on, we&#39;ll see how to use more
powerful kinds of data sources for representing multiple rows from
an SQL query. You also include overall documentation for the page
in the contract, and OpenACS has automatic tools that extract this
documentation and make it browsable.</p></li><li class="listitem"><p>After being declared in the <code class="computeroutput">ad_page_contract</code>, each property is just a
simple Tcl variable. The template system passes the final value of
the variable to the <code class="computeroutput">.adp</code>
template when the <code class="computeroutput">.tcl</code> file is
processed.</p></li><li class="listitem"><p>The call <code class="computeroutput">ad_return_template</code>
tells the template system what <code class="computeroutput">.adp</code> template page to fetch to display the
properties that have been processed. By default, the template
system will look for a file by the same name as the <code class="computeroutput">.tcl</code> file that just ran, but with an
<code class="computeroutput">.adp</code> extension.</p></li>
</ul></div><p>Next we write the corresponding <code class="computeroutput">.adp</code> page. This page outputs HTML for the
form, and also contains placeholders whose values are substituted
in from the properties set up by the <code class="computeroutput">.tcl</code> file. Create a file called
<code class="computeroutput">note-add.adp</code> in your editor,
and insert this text:</p><pre class="programlisting">

&lt;master src="master"&gt;
&lt;property name="title"&gt;\@page_title;literal\@&lt;/property&gt;
&lt;property name="context_bar"&gt;\@context_bar;literal\@&lt;/property&gt;

&lt;form action="\@target\@"&gt;
&lt;p&gt;Title: 
&lt;input type="text" name="title" value=""&gt;
&lt;/p&gt;
&lt;p&gt;Body: 
&lt;input type="text" name="title" value=""&gt;
&lt;/p&gt;
&lt;p&gt;
&lt;center&gt;
&lt;input type="submit" value="\@submit_label\@"&gt;
&lt;/center&gt;
&lt;/p&gt;
&lt;/form&gt;

</pre><p>The main point to note here is: when you want to substitute a
value into a page, you put the name of the data source between two
"\@" characters. Another point to note is the use of a
master template: Master templates allow you do centralize display
code that is used throughout an application in a single file. In
this case, we intend to have a master template that does the
standard page headers and footers for us</p><p>After putting all these files into <code class="computeroutput">ROOT/packages/notes/www</code>, you should be able
to go to <code class="computeroutput">/notes/</code> URL for your
server and see the input form.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="templates-summary" id="templates-summary"></a>Summary</h3></div></div></div><p>Templates separate application logic from display logic by
requiring the developer to write pages in two stages, one file for
database queries and application logic, and another for display. In
OpenACS, the logic part of the page is just a <code class="computeroutput">.tcl</code> that sets up <span class="emphasis"><em>data sources</em></span> that are used by the
display part of the page. The display part of the page is an
<code class="computeroutput">.adp</code> file with some special
tags and notations for dealing with display logic and inserting
properties into the text of the page. Later on we&#39;ll get into
templates more deeply, and show how to use database queries as data
sources.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="templates-documentation" id="templates-documentation"></a>Documentation</h3></div></div></div><p><a class="ulink" href="/doc/acs-templating/" target="_top">Templating system documentation</a></p><div class="cvstag">($&zwnj;Id: templates.xml,v 1.12.2.1 2016/06/23
08:32:46 gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="db-api" leftLabel="Prev" leftTitle="The OpenACS Database Access API"
		    rightLink="permissions" rightLabel="Next" rightTitle="Groups, Context, Permissions"
		    homeLink="index" homeLabel="Home" 
		    upLink="dev-guide" upLabel="Up"> 
		