
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {OpenACS Data Models and the Object System}</property>
<property name="doc(title)">OpenACS Data Models and the Object System</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="packages" leftLabel="Prev"
		    title="
Chapter 11. Development Reference"
		    rightLink="request-processor" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="objects" id="objects"></a>OpenACS Data Models and the Object System</h2></div></div></div><div class="authorblurb">
<p>By Pete Su</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="objects-overview" id="objects-overview"></a>Overview</h3></div></div></div><p>Developing data models in OpenACS 5.9.0 is much like developing
data models for OpenACS 3, save for the implementation. As usual,
you need to examine how to model the information that the
application must store and manipulate, and define a suitable set of
SQL tables. In our Notes application, we have to be able to keep
track of who entered a particular note, when they did it, and the
actual text of the notes that users have entered. A simple data
model might look like this:</p><pre class="programlisting">
create table notes (
    note_id           integer primary key,
    owner_id          integer references users(user_id),
    creation_user     references(user_id) not null,
    creation_date     date not null,
    last_modified     date not null,
    title             varchar(255) not null,
    body              varchar(1024)
)
</pre><p>We&#39;ve omitted constraint names for the purpose of
clarity.</p><p>Thinking further ahead, we can imagine doing any of the
following things with Notes as well:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: opencircle;">
<li class="listitem" style="list-style-type: circle"><p>Define access control policies on notes.</p></li><li class="listitem" style="list-style-type: circle"><p>Attach user comments on notes.</p></li><li class="listitem" style="list-style-type: circle"><p>Allow users to define custom fields to store on their notes.</p></li><li class="listitem" style="list-style-type: circle"><p>Automatically generate input forms or output displays for
notes.</p></li><li class="listitem" style="list-style-type: circle"><p>Allow other applications to use notes in ways we don&#39;t know
of yet.</p></li>
</ul></div><p>In OpenACS, the key to enabling these types of services on your
application data is to take advantage of the Object System. The
first question, then, is "Just what are objects, and what do
you use them for anyway?". The short answer: objects are
anything represented in the application&#39;s data model that will
need to be managed by any central service in OpenACS, or that may
be reusable in the context of future applications. Every object in
the system is represented using a row in the <code class="computeroutput">acs_objects</code> table. This table defines all
the standard attributes that are stored on every object, including
its system-wide unique ID, object type, and some generic auditing
columns.</p><p>To make use of the object system, you as the application
developer have to write your data model in a way that is slightly
more complex than in the ACS 3.x days. What you get for this extra
work includes:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The <a class="xref" href="permissions" title="Groups, Context, Permissions">Permissions System</a> lets you
track who is allowed to do what to the rows in an application
table, and gives you an easy way to enforce this from Tcl.</p></li><li class="listitem"><p>Every object has an attribute called <code class="computeroutput">context_id</code> that provides a way to trivially
specify both the default permissions for an object, and the
intended "scope" of an object. Just set the <code class="computeroutput">context_id</code> to the controlling object and
forget about it.</p></li><li class="listitem"><p>And most importantly, any future object-level service - from a
general-comments replacement to personalized ranking - will become
available to your application "for free."</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="objects-how-to-use" id="objects-how-to-use"></a>How to Use Objects</h3></div></div></div><p>Using ACS objects is straightforward: all that&#39;s required
are a few extra steps in the design of your application data
model.</p><p>In order to hook our Notes application into the object system,
we make some calls to use our <code class="computeroutput">notes</code> table as the basis for a new
<span class="emphasis"><em>object type</em></span>. Object types
are analogous to classes in programming languages such as C++ and
Java. In Java, a class defines a set of attributes that store data
and a set of methods that run code. In OpenACS, we use one or more
database tables to store the data attributes, and we define a
stored procedure package to hold procedures to define the
programming interface to the data model.</p><p>The object type itself is described using data in the
<code class="computeroutput">acs_object_types</code> and
<code class="computeroutput">acs_attributes</code> tables, which
play a role similar to the data dictionary in Oracle. As in Java,
object types can inherit attributes from a parent type, so the type
system forms a hierarchy. Unlike Java, Oracle does not support this
inheritance transparently, so we have to make sure we add our own
bookkeeping code to keep everything consistent. Below you&#39;ll
find the code needed to describe a new object type called
<code class="computeroutput">notes</code> in your system.</p><p>Fire up your text editor and open the <code class="computeroutput">ROOT/packages/notes/sql/oracle/notes-create.sql</code>
(<code class="computeroutput">ROOT/packages/notes/sql/postgresql/notes-create.sql</code>
for the PG version) file created when we <a class="link" href="packages" title="OpenACS Packages">created the package</a>.
Then, do the following:</p><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140592100229608" id="idp140592100229608"></a>Describe the new type to the type
system</h4></div></div></div><p>First, add an entry to the <code class="computeroutput">acs_object_types</code> table with the following
PL/SQL call:</p><pre class="programlisting">
begin  
  acs_object_type.create_type ( 
    supertype     =&gt; 'acs_object', 
    object_type   =&gt; 'note', 
    pretty_name   =&gt; 'Note', 
    pretty_plural =&gt; 'Notes', 
    table_name    =&gt; 'NOTES', 
    id_column     =&gt; 'NOTE_ID' 
  ); 
end;
/
show errors;
</pre><p>This PL/SQL call tells the system that we would like to use the
table <code class="computeroutput">NOTES</code> as the basis for a
new object type called <code class="computeroutput">note</code>.
This type is a subtype of the <code class="computeroutput">acs_object</code> type, which means that we want
to inherit all of the basic attributes of all ACS objects. As
mentioned, it will take some work on our part to make this happen,
since Oracle can&#39;t do it automatically. In general, most basic
applications will define types that are simple subtypes of
<code class="computeroutput">acs_object</code>.</p><p>Add entries to the <code class="computeroutput">acs_attributes</code> table to describe the data
attributes of the new type. This data can eventually be used to do
things like automatically generate user interfaces to manipulate
the <code class="computeroutput">notes</code> table, though that
functionality isn&#39;t yet available.</p><pre class="programlisting">
declare 
 attr_id acs_attributes.attribute_id%TYPE; 
begin
  attr_id := acs_attribute.create_attribute ( 
    object_type    =&gt; 'note', 
    attribute_name =&gt; 'TITLE', 
    pretty_name    =&gt; 'Title', 
    pretty_plural  =&gt; 'Titles', 
    datatype       =&gt; 'string' 
  ); 
 
  attr_id := acs_attribute.create_attribute ( 
    object_type    =&gt; 'note', 
    attribute_name =&gt; 'BODY', 
    pretty_name    =&gt; 'Body', 
    pretty_plural  =&gt; 'Bodies', 
    datatype       =&gt; 'string' 
  ); 
end; 
/ 
show errors; 
</pre><p>We can stop here and not bother to register the usual OpenACS
3.x attributes of <code class="computeroutput">creation_user</code>, <code class="computeroutput">creation_date</code> and <code class="computeroutput">last_modified</code>, since the object type
<code class="computeroutput">acs_object</code> already defines
these attributes. Again, because the new type <code class="computeroutput">note</code> is a subtype of <code class="computeroutput">acs_object</code>, it will inherit these
attributes, so there is no need for us to define them.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140592105765448" id="idp140592105765448"></a>Define a table in which to store your
objects</h4></div></div></div><p>The next thing we do is make a small modification to the data
model to reflect the fact that each row in the <code class="computeroutput">notes</code> table represents something that is
not only an object of type <code class="computeroutput">note</code>, but also an <code class="computeroutput">acs_object</code>. The new table definition looks
like this:</p><pre class="programlisting">
create table notes (
    note_id    integer references acs_objects(object_id) primary key,
    owner_id   integer references users(user_id),
    title      varchar(255) not null,
    body       varchar(1024)
)
</pre><p>The usual <code class="computeroutput">creation_date</code> and
<code class="computeroutput">modified_date</code> columns are
absent since they already exist in <code class="computeroutput">acs_objects</code>. Also, note the constraint we
have added to reference the <code class="computeroutput">acs_objects</code> table, which makes clear that
since <code class="computeroutput">note</code> is a subtype of
<code class="computeroutput">acs_object</code>, every row in the
notes table must have a corresponding row in the <code class="computeroutput">acs_objects</code> table. This is the fundamental
means by which we model inheritance; it guarantees that any
services that use the <code class="computeroutput">acs_objects</code> table to find objects will
transparently find any objects that are instances of any subtype of
<code class="computeroutput">acs_objects</code>.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140592105775736" id="idp140592105775736"></a>Define a package for type specific
procedures</h4></div></div></div><p>The next step is to define a PL/SQL package for your new type,
and write some basic procedures to create and delete objects. Here
is a package definition for our new type:</p><pre class="programlisting">
create or replace package note 
as 
  function new ( 
    note_id             in notes.note_id%TYPE default null, 
    owner_id            in notes.owner_id%TYPE default null, 
    title               in notes.title%TYPE, 
    body                in notes.body%TYPE, 
    object_type         in acs_object_types.object_type%TYPE default 'note', 
    creation_date       in acs_objects.creation_date%TYPE 
                           default sysdate, 
    creation_user       in acs_objects.creation_user%TYPE 
                           default null, 
    creation_ip         in acs_objects.creation_ip%TYPE default null, 
    context_id          in acs_objects.context_id%TYPE default null 
  ) return notes.note_id%TYPE; 
 
  procedure delete ( 
    note_id      in notes.note_id%TYPE 
  ); 
end note; 
/ 
show errors 
</pre><p>You might be wondering what all the extra parameters are to
these calls, since we haven&#39;t mentioned them before. These
parameters are needed to fill out information that will be stored
about the object that&#39;s not stored directly in the table you
defined. The OpenACS Object System defines these attributes on the
type <code class="computeroutput">acs_object</code> since all
objects should have these attributes. Internally, there are tables
that store this information for you. Most of the data is pretty
self-explanatory and reflects attributes that existed in the
earlier OpenACS 3.x data models, with the exception of the
<code class="computeroutput">context_id</code> attribute.</p><p>The <code class="computeroutput">context_id</code> attribute
stores the ID of an object that represents the default security
domain to which the object belongs. It is used by the <a class="link" href="permissions" title="Groups, Context, Permissions">permissions</a> system in this way:
if no permissions are explicitly attached to the object, then the
object inherits its permissions from the context. For example, if I
had told you how to use the <a class="link" href="permissions" title="Groups, Context, Permissions">permissions</a> system to
specify that an object OBJ was "read only", then any
other object that used OBJ as its context would also be "read
only" by default. We&#39;ll talk about this more later.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140592105783448" id="idp140592105783448"></a>Define a package body for type specific
procedures</h4></div></div></div><p>The PL/SQL package body contains the implementations of the
procedures defined above. The only subtle thing going on here is
that we must use <code class="computeroutput">acs_object.new</code>
to insert a row into <code class="computeroutput">acs_objects</code>, before inserting a row into
the <code class="computeroutput">notes</code>. Similarly, when we
delete a row from <code class="computeroutput">note</code>, we have
to be sure to delete the corresponding <code class="computeroutput">acs_object</code> row.</p><pre class="programlisting">
create or replace package body note 
as 
 
  function new ( 
    note_id             in notes.note_id%TYPE default null, 
    owner_id            in notes.owner_id%TYPE default null, 
    title               in notes.title%TYPE, 
    body                in notes.body%TYPE, 
    object_type         in acs_object_types.object_type%TYPE default 'note', 
    creation_date       in acs_objects.creation_date%TYPE 
                           default sysdate, 
    creation_user       in acs_objects.creation_user%TYPE 
                           default null, 
    creation_ip         in acs_objects.creation_ip%TYPE default null, 
    context_id          in acs_objects.context_id%TYPE default null 
  ) return notes.note_id%TYPE 
  is 
    v_note_id integer; 
  begin 
    v_note_id := acs_object.new ( 
      object_id     =&gt; note_id, 
      object_type   =&gt; object_type, 
      creation_date =&gt; creation_date, 
      creation_user =&gt; creation_user, 
      creation_ip   =&gt; creation_ip, 
      context_id    =&gt; context_id 
    ); 
    
    insert into notes 
     (note_id, owner_id, title, body) 
    values 
     (v_note_id, owner_id, title, body); 
 
     return v_note_id; 
  end new; 
  
  procedure delete ( 
    note_id      in notes.note_id%TYPE 
  ) 
  is 
  begin 
    delete from notes 
    where note_id = note.delete.note_id; 
 
    acs_object.del(note_id); 
  end delete; 
 
end note; 
/ 
show errors; 
</pre><p>That&#39;s pretty much it! As long as you use the <code class="computeroutput">note.new</code> function to create notes, and the
<code class="computeroutput">note.delete</code> function to delete
them, you&#39;ll be assured that the relationship each <code class="computeroutput">note</code> has with its corresponding
<code class="computeroutput">acs_object</code> is preserved.</p><p>The last thing to do is to make a file <code class="computeroutput">ROOT/packages/notes/sql/notes-drop.sql</code> so
it&#39;s easy to drop the data model when, say, you&#39;re
testing:</p><pre class="programlisting">
begin 
  acs_object_type.drop_type ('note'); 
end; 
/ 
show errors 
 
drop package note; 
drop table notes; 
</pre>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="objects-when-to-use-objects" id="objects-when-to-use-objects"></a>When to Use Objects</h3></div></div></div><p>While it is hard to give general design advice without knowing
anything about a particular application, you should follow the
following rule of thumb when deciding when to hook part of your
data model to the object system:</p><p>Anything in your data model that needs to be available to
general OpenACS services such as user comments, permissions, and so
on should be a subtype of <code class="computeroutput">acs_object</code>. In addition, if you want your
data model to take advantage of attributes that exist in some
object type that is a subtype of <code class="computeroutput">acs_object</code>, then you should use the object
system.</p><p>For example, for most applications, you will want to use objects
to represent the data in your application that is user visible and
thus requires access control. But other internal tables, views,
mapping tables and so on probably don&#39;t need to be objects. As
before, this kind of design decision is mostly made on an
application-by-application basis, but this is a good baseline from
which to start.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="objects-design-guidance" id="objects-design-guidance"></a>Design Guidance</h3></div></div></div><p>In this section we cover some overall guidelines for designing
data models that are meant to be integrated with the OpenACS object
system.</p><p>There are two basic rules you should follow when designing
OpenACS 5.9.0 data models:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Never utilize fields in the <code class="computeroutput">acs_objects</code> table in application specific
ways. That is, never assign any application-specific semantics to
this data. In the notes application, we use the <code class="computeroutput">creation_date</code> and <code class="computeroutput">last_modified</code> fields, but this is OK since
we do not assign any application-specific meaning to these
fields.</p></li><li class="listitem">
<p>In particular, never assign any application specific semantics
to the <code class="computeroutput">context_id</code> attribute of
an object. This field is used for a very specific purpose by the
permissions system, and using this field in <span class="emphasis"><em>any other way whatsoever</em></span> is guaranteed
to make your application act strangely.</p><p>As we&#39;ll see later, the Notes example will point each note
object&#39;s <code class="computeroutput">context_id</code> to the
package instance in which the note was created. The idea will be
that in a real site, the administrator would create one package
instance for every separate set of Notes (say, one per user). The
instance would "own" all of the notes that it created,
and the administrator would be able to use the package instance as
the basis for access control, which is convenient.</p>
</li>
</ol></div><p>The reason behind these two rules is pretty straightforward:
First, the OpenACS Object system itself is meant to be a generic
and reusable tool for any application to use for basic services.
Second, in order for this to work, the various parts of the OpenACS
Objects data model must be interpreted in the same way by all
applications that use the data model. Therefore, assigning any
application-specific semantics to any part of the core data model
is a bad thing to do, because then the semantics of the data model
are no longer independent of the application. This would make it
impossible to build the generic tools that the data model is trying
to support.</p><p>Another less important reason for these two rules is to not
introduce any joins against the <code class="computeroutput">acs_objects</code> table in SQL queries in your
application that you do not absolutely need.</p><p>In the Notes example, the result of applying these rules is that
we are careful to define our own attribute for <code class="computeroutput">owner_id</code> rather than overloading
<code class="computeroutput">creation_user</code> from the objects
table. But, since we will probably use <code class="computeroutput">creation_date</code> and so on for their intended
purposes, we don&#39;t bother to define our own attributes to store
that data again. This will entail joins with <code class="computeroutput">acs_objects</code> but that&#39;s OK because it
makes the overall data model cleaner. The real lesson is that
deciding exactly how and when to use inherited attributes is fairly
straightforward, but requires a good amount of thought at design
time even for simple applications.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="objects-summary" id="objects-summary"></a>Summary</h3></div></div></div><p>Hooking into the OpenACS 5.9.0 object system brings the
application developer numerous benefits, and doing it involves only
four easy steps:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: opencircle;">
<li class="listitem" style="list-style-type: circle"><p>Describe the a new object type to the system. Most new
application types will be subtypes of the built-in type
<code class="computeroutput">acs_object</code>.</p></li><li class="listitem" style="list-style-type: circle"><p>Define a table to store application object data.</p></li><li class="listitem" style="list-style-type: circle"><p>Define a PL/SQL package to store procedures related to the new
type. You have to define at least a function called <code class="computeroutput">new</code> to create new application objects and a
procedure called <code class="computeroutput">delete</code> to
delete them.</p></li><li class="listitem" style="list-style-type: circle"><p>Define a package body that contains the implementations of the
PL/SQL procedures defined above.</p></li><li class="listitem" style="list-style-type: circle"><p>Try not to write queries in your application that join against
<code class="computeroutput">acs_objects</code>. This means you
should never use the fields in <code class="computeroutput">acs_objects</code> for application-specific
purposes. This is especially true for the <code class="computeroutput">context_id</code> field.</p></li>
</ul></div><div class="cvstag">($&zwnj;Id: objects.xml,v 1.9.14.1 2016/06/23
08:32:46 gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="packages" leftLabel="Prev" leftTitle="OpenACS Packages"
		    rightLink="request-processor" rightLabel="Next" rightTitle="The Request Processor"
		    homeLink="index" homeLabel="Home" 
		    upLink="dev-guide" upLabel="Up"> 
		