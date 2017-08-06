
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Setting Up Database Objects}</property>
<property name="doc(title)">Setting Up Database Objects</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-newpackage" leftLabel="Prev"
		    title="
Chapter 9. Development Tutorial"
		    rightLink="tutorial-pages" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-database" id="tutorial-database"></a>Setting Up Database Objects</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel Aufrecht</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140592104860472" id="idp140592104860472"></a>Code the data model</h3></div></div></div><p>We create all database objects with scripts in the <code class="computeroutput">myfirstpackage/sql/</code> directory. All database
scripts are database-specific and are thus in either the
<code class="computeroutput">myfirstpackage/sql/oracle</code> or
<code class="computeroutput">myfirstpackage/sql/postgresql</code>
directory. Packages can support Oracle, PostgreSQL, or both. In
this tutorial, we will be working with PostgreSQL</p><p>The first file will be <code class="computeroutput">myfirstpackage-create.sql</code>. The package
manager requires a file with the name <code class="computeroutput">
<span class="replaceable"><span class="replaceable">packagekey</span></span>-create.sql</code>, which it
will run automatically when the package in installed. This file
should create all tables and views.</p><p>Our package is going to store all of its information in one
table. It takes more than just a <code class="computeroutput">CREATE TABLE</code> command, however, because we
want to integrate our table with the OpenACS system. By making each
record in our table an OpenACS object, we gain access to the
permissions system and to services that integrate with OpenACS
objects, such as <code class="computeroutput">general-comments</code> and <code class="computeroutput">notification</code>. The cost is that our table
creation code must include several functions, stored procedures,
and is complicated (even for simple tables).</p><p>There are many kinds of OpenACS objects in the system. (You can
see them with the psql code: <code class="computeroutput">select
object_type from acs_object_types;</code>.) One such object is the
content_item, which is part of the content repository system. To
use it, we will make our data objects children of the
content_revision object, which is a child of content_item. Not only
will we gain the benefits of both OpenACS Objects and content
objects, we can also use some content repository functions to
simplify our database creation. (<a class="ulink" href="objects" target="_top">More information about ACS
Objects</a>. <a class="ulink" href="/doc/acs-content-repository" target="_top">More information about the Content
Repository</a>.)</p><div class="figure">
<a name="idp140592094116616" id="idp140592094116616"></a><p class="title"><strong>Figure 9.2. Tutorial Data
Model</strong></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/tutorial-data-model.png" align="middle" alt="Tutorial Data Model"></div></div>
</div><br class="figure-break"><p>The top of each sql file has some standard comments, including
doc tags such as <code class="computeroutput">\@author</code> which
will be picked up by the API browser. The string <code class="computeroutput">$&zwnj;Id:$</code> will automatically be expanded when
the file is checked in to cvs.</p><pre class="screen">
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/sql/postgresql</code></strong>
[$OPENACS_SERVICE_NAME postgresql]$ <strong class="userinput"><code>emacs myfirstpackage-create.sql</code></strong>
</pre><p>Paste the text below into the file, save, and close.</p><div class="figure">
<a name="idp140592098943512" id="idp140592098943512"></a><p class="title"><strong>Figure 9.3. The
Database Creation Script</strong></p><div class="figure-contents"><pre class="programlisting">
-- creation script
--
-- \@author joel\@aufrecht.org
-- \@cvs-id &amp;Id:$
--

select content_type__create_type(
    'mfp_note',                    -- content_type
    'content_revision',            -- supertype
    'MFP Note',                    -- pretty_name,
    'MFP Notes',                   -- pretty_plural
    'mfp_notes',                   -- table_name
    'note_id',                     -- id_column
    null                           -- name_method
);

-- necessary to work around limitation of content repository:
select content_folder__register_content_type(-100,'mfp_note','t');
</pre></div>
</div><br class="figure-break"><p>The creation script calls a function in PL/pgSQL (PL/pgSQL is a
procedural language extension to sql), <code class="computeroutput"><a class="ulink" href="/api-doc/plsql-subprogram-one?type=FUNCTION&amp;name=content%5ftype%5f%5fcreate%5ftype" target="_top">content_type__create_type</a></code>, which in turn
creates the necessary database changes to support our data object.
Notice the use of "mfp." This is derived from "My
First Package" and ensures that our object is unlikely to
conflict with objects from other packages.</p><p>Create a database file to drop everything if the package is
uninstalled.</p><pre class="screen">
[$OPENACS_SERVICE_NAME postgresql]$ <strong class="userinput"><code>emacs myfirstpackage-drop.sql</code></strong>
</pre><div class="figure">
<a name="idp140592099179128" id="idp140592099179128"></a><p class="title"><strong>Figure 9.4. Database Deletion
Script</strong></p><div class="figure-contents"><pre class="programlisting">
-- drop script
--
-- \@author joel\@aufrecht.org
-- \@cvs-id &amp;Id:$
--
select content_folder__unregister_content_type(-100,'mfp_note','t');

select content_type__drop_type(
           'mfp_note',
           't',
           't'
    );
</pre></div>
</div><br class="figure-break"><p>(like the creation script the drop script calls a PL/pgSQL
function: <code class="computeroutput"><a class="ulink" href="/api-doc/plsql-subprogram-one?type=FUNCTION&amp;name=content%5ftype%5f%5fdrop%5ftype" target="_top">content_type__drop_type</a></code>
</p><p>Run the create script manually to add your tables and
functions.</p><pre class="screen">
[$OPENACS_SERVICE_NAME postgresql]$ <strong class="userinput"><code>psql service0 -f myfirstpackage-create.sql</code></strong>
psql:myfirstpackage-create.sql:15: NOTICE:  CREATE TABLE / PRIMARY KEY will create implicit index 'mfp_notes_pkey' for table 'mfp_notes'
psql:myfirstpackage-create.sql:15: NOTICE:  CREATE TABLE will create implicit trigger(s) for FOREIGN KEY check(s)
 content_type__create_type
---------------------------
                         0
(1 row)

[$OPENACS_SERVICE_NAME postgresql]$
</pre><p>If there are errors, use them to debug the sql file and try
again. If there are errors in the database table creation, you may
need to run the drop script to drop the table so that you can
recreate it. The drop script will probably have errors since some
of the things it&#39;s trying to drop may be missing. They can be
ignored.</p><p>Once you get the same output as shown above, test the drop
script:</p><pre class="screen">
[$OPENACS_SERVICE_NAME postgresql]$ <strong class="userinput"><code>psql service0 -f myfirstpackage-drop.sql</code></strong>

 content_type__drop_type
-------------------------
                       0
(1 row)

[$OPENACS_SERVICE_NAME postgresql]$
</pre><p>Once both scripts are working without errors, <span class="emphasis"><em>run the create script one last time</em></span> and
proceed.</p><pre class="screen">
[$OPENACS_SERVICE_NAME postgresql]$ <strong class="userinput"><code>psql service0 -f myfirstpackage-create.sql</code></strong>
</pre>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-newpackage" leftLabel="Prev" leftTitle="Creating an Application Package"
		    rightLink="tutorial-pages" rightLabel="Next" rightTitle="Creating Web Pages"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial" upLabel="Up"> 
		