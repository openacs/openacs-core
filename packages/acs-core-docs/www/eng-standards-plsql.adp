
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {PL/SQL Standards}</property>
<property name="doc(title)">PL/SQL Standards</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="eng-standards-filenaming" leftLabel="Prev"
		    title="
Chapter 12. Engineering Standards"
		    rightLink="variables" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="eng-standards-plsql" id="eng-standards-plsql"></a>PL/SQL Standards</h2></div></div></div><div class="authorblurb">
<p>By Richard Li and Yon Feldman</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>Like any other part of the OpenACS, PL/SQL (or pl/pgsql) code
must be maintainable and professional. This means that it must be
consistent and therefore must abide by certain standards. The
standards will ensure that our product will be useful long after
the current people building and maintaining it are around.
Following are some standards and guidelines that will help us
achieve this goal:</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-plsql-general" id="eng-standards-plsql-general"></a>General</h3></div></div></div><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>All PL/SQL code must be well documented. We must write code that
is maintainable by others, this is especially true in our case
because we are building an open source toolkit than anyone can
download and browse the source code. So document like you are
trying to impress your "Introduction to Programming"
professor or TA.</p></li><li class="listitem"><p>It is important to be consistent throughout an application as
much as is possible given the nature of team development. This
means carrying style and other conventions suchs as naming within
an application, not just within one file.</p></li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-plsql-code" id="eng-standards-plsql-code"></a>Code</h3></div></div></div><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Encapsulation of related fuctionality is key to maintainability
and upgradeability of our software. Try to bundle your code into
<a class="ulink" href="https://docs.oracle.com/database/121/LNPLS/packages.htm#LNPLS009" target="_top">packages</a> whenever possible. This will make
upgrading, bug fixing, and customizing, among other things, a
possibility.</p></li><li class="listitem">
<p>When creating functions or procedures use the following
template, it demonstrates most of the guidelines set forth in this
document that correspond to functions and procedures:</p><pre class="programlisting">
 
        create or replace procedure|function &lt;proc_or_func_name&gt; (
                 &lt;param_1&gt;    in|out|inout &lt;datatype&gt;,
                 &lt;param_2&gt;    in|out|inout &lt;datatype&gt;,
                 ...
                 &lt;param_n&gt;    in|out|inout &lt;datatype&gt;
        )
        [return &lt;datatype&gt;]
        is
                &lt;local_var_1&gt;    &lt;datatype&gt;
                &lt;local_var_2&gt;    &lt;datatype&gt;
                ...
                &lt;local_var_n&gt;    &lt;datatype&gt;
        begin
                ...
        end &lt;proc_or_func_name&gt;;
        /
        show errors
     
</pre>
</li><li class="listitem"><p>Always use <code class="computeroutput">create or replace
procedure|function &lt;proc_or_func_name&gt;</code>. It makes
reloading packages much easier and painless to someone who is
upgrading or fixing a bug.</p></li><li class="listitem"><p>Always qualify <code class="computeroutput">end</code>
statements, i.e., the <code class="computeroutput">end</code>
statement for a package should be <code class="computeroutput">end
&lt;package_name&gt;;</code>, not just <code class="computeroutput">end;</code>; same goes for procedures, functions,
package bodies, and triggers.</p></li><li class="listitem"><p>Always use the "show errors" SQL*Plus command after
each PL/SQL block. It will help you debug when there are
compilation errors in your PL/SQL code.</p></li><li class="listitem">
<p>Name parameters as simply as possible, i.e., use the column name
if the parameter corresponds to a table column. We&#39;re
deprecating the v_* and *_in syntax in favor of named parameters
notation:</p><pre class="programlisting">
<code class="computeroutput">
        acs_user.create(first_names =&gt; 'Jane', last_name =&gt; 'Doe', etc.)
      </code>
        instead of
      <code class="computeroutput">
        acs_user.create(first_names_in =&gt; 'Jane', last_name_in =&gt; 'Doe', etc.)
      </code>
</pre><p>To achieve this we must fully qualify arguments passed into
procedures or functions when using them inside a SQL statement.
This will get rid of any ambiguities in your code, i.e. it will
tell the parser when you want the value of the column and when you
want the value from the local variable. Here is an example:</p><pre class="programlisting">

        create or replace package body mypackage 
            .
            .
            procedure myproc(party_id in parties.party_id%TYPE) is begin
                .
                .
                delete
                  from parties
                 where party_id = myproc.party_id;
                .
                .
            end myproc;
            .
            .
        end mypackage;
        /
        show errors
     
</pre>
</li><li class="listitem"><p>Explicitly designate each parameter as "in,"
"out," or "inout."</p></li><li class="listitem"><p>Each parameter should be on its own line, with a tab after the
parameter name, then in/out/inout, then a space, and finally the
datatype.</p></li><li class="listitem"><p>Use %TYPE and %ROWTYPE whenever possible.</p></li><li class="listitem"><p>Use 't' and 'f' for booleans, not the PL/SQL
"boolean" datatype because it can&#39;t be used in SQL
queries.</p></li><li class="listitem">
<p>All <code class="computeroutput">new</code> functions (e.g.,
<code class="computeroutput">acs_object.new, party.new,</code>
etc.) should optionally accept an ID:</p><pre class="programlisting"><code class="computeroutput">
        create or replace package acs_object
        as
            function new (
                object_id       in acs_objects.object_id%TYPE default null,
                object_type     in acs_objects.object_type%TYPE default 'acs_object',
                creation_date   in acs_objects.creation_date%TYPE default sysdate,
                creation_user   in acs_objects.creation_user%TYPE default null,
                creation_ip     in acs_objects.creation_ip%TYPE default null,
                context_id      in acs_objects.context_id%TYPE default null
           ) return acs_objects.object_id%TYPE;
     </code></pre><p>takes the optional argument <code class="computeroutput">object_id</code>. Do this to allow people to use
the same API call when they are doing double click protection, that
is, they have already gotten an <code class="computeroutput">object_id</code> and now they want to create the
object with that <code class="computeroutput">object_id</code>.</p>
</li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-style" id="eng-standards-style"></a>Style</h3></div></div></div><p>Some general style guidelines to follow for the purpose of
consistency across applications.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Standard indentation is 4 spaces. Our PL/SQL code is not only
viewable in the SQL files but also through our SQL and PL/SQL
browsers. This means that we should try to make it as consistent as
possible to all source code readers.</p></li><li class="listitem"><p>Lowercase everything, with the exception of %TYPE and
%ROWTYPE.</p></li>
</ol></div><div class="cvstag">($&zwnj;Id: plsql.xml,v 1.6.14.3 2017/06/16 17:19:52
gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="eng-standards-filenaming" leftLabel="Prev" leftTitle="ACS File Naming and Formatting
Standards"
		    rightLink="variables" rightLabel="Next" rightTitle="Variables"
		    homeLink="index" homeLabel="Home" 
		    upLink="eng-standards" upLabel="Up"> 
		