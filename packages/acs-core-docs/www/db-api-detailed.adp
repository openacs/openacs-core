
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Database Access API}</property>
<property name="doc(title)">Database Access API</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="apm-design" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="i18n-requirements" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="db-api-detailed" id="db-api-detailed"></a>Database Access API</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="mailto:jsalz\@mit.edu" target="_top">Jon Salz</a>. Revised and expanded by Roberto Mello (rmello
at fslc dot usu dot edu), July 2002.</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Tcl procedures: /packages/acs-kernel/10-database-procs.tcl</p></li><li class="listitem"><p>Tcl initialization: /packages/acs-kernel/database-init.tcl</p></li>
</ul></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-detailed-bigpicture" id="db-api-detailed-bigpicture"></a>The Big Picture</h3></div></div></div><p>One of OpenACS&#39;s great strengths is that code written for it
is very close to the database. It is very easy to interact with the
database from anywhere within OpenACS. Our goal is to develop a
coherent API for database access which makes this even easier.</p><p>There were four significant problems with the way OpenACS
previously used the database (i.e., directly through the
<code class="computeroutput">ns_db</code> interface):</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<span class="strong"><strong>Handle management</strong></span>.
We required code to pass database handles around, and for routines
which needed to perform database access but didn&#39;t receive a
database handle as input, it was difficult to know from which of
the three "magic pools" (main, subquery, and log) to
allocate a new handle.</p></li><li class="listitem">
<p>
<span class="strong"><strong>Nested
transactions</strong></span>. In our Oracle driver, <code class="computeroutput">begin transaction</code> really means "turn
auto-commit mode off" and <code class="computeroutput">end
transaction</code> means "commit the current transaction and
turn auto-commit mode on." Thus if transactional code needed
to call a routine which needed to operate transactionally, the
semantics were non-obvious. Consider:</p><pre class="programlisting">

proc foo { db args } {
    db_transaction {
      ...
    }
}

db_transaction {
   db_dml unused {insert into greeble(bork) values(33)}
   foo $db
   db_dml unused {insert into greeble(bork) values(50)}
}

</pre><p>This would insert greeble #33 and do all the stuff in
<code class="computeroutput">foo</code> transactionally, but the
<code class="computeroutput">end transaction</code> in <code class="computeroutput">foo</code> would actually cause a commit, and
greeble #50 would later be inserted in auto-commit mode. This could
cause subtle bugs: e.g., in the case that the insert for greeble
#50 failed, part of the "transaction" would have already
have been committed!. This is not a good thing.</p>
</li><li class="listitem"><p>
<span class="strong"><strong>Unorthodox use of
variables</strong></span>. The standard mechanism for mapping
column values into variables involved the use of the <code class="computeroutput">set_variables_after_query</code> routine, which
relies on an uplevel variable named <code class="computeroutput">selection</code> (likewise for <code class="computeroutput">set_variables_after_subquery</code> and
<code class="computeroutput">subselection</code>).</p></li><li class="listitem"><p>
<span class="strong"><strong>Hard-coded reliance on
Oracle</strong></span>. It&#39;s difficult to write code supporting
various different databases (dynamically using the appropriate
dialect based on the type of database being used, e.g., using
<code class="computeroutput">DECODE</code> on Oracle and
<code class="computeroutput">CASE ... WHEN</code> on Postgres).</p></li>
</ol></div><p>The Database Access API addresses the first three problems
by:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>making use of database handles transparent</p></li><li class="listitem"><p>wrapping common database operations (including transaction
management) in Tcl control structures (this is, after all, what Tcl
is good at!)</p></li>
</ol></div><p>It lays the groundwork for addressing the fourth problem by
assigning each SQL statement a logical name. In a future version of
the OpenACS Core, this API will translate logical statement names
into actual SQL, based on the type of database in use. (To smooth
the learning curve, we provide a facility for writing SQL inline
for a "default SQL dialect", which we assume to be Oracle
for now.)</p><p>To be clear, SQL abstraction is <span class="emphasis"><em>not</em></span> fully implemented in OpenACS 3.3.1.
The statement names supplied to each call are not used by the API
at all. The API&#39;s design for SQL abstraction is in fact
incomplete; unresolved issues include:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>how to add <code class="computeroutput">WHERE</code> clause
criteria dynamically</p></li><li class="listitem"><p>how to build a dynamic <code class="computeroutput">ORDER
BY</code> clause (Ben Adida has a proposed solution for this)</p></li><li class="listitem"><p>how to define a statement&#39;s formal interface (i.e., what
bind variables it expects, what columns its <code class="computeroutput">SELECT</code> clause must contain if it&#39;s a
query) without actually implementing the statement in a specific
SQL dialect</p></li>
</ul></div><p>So why is the incremental change of adding statement naming to
the API worth the effort? It is worth the effort because we know
that giving each SQL statement a logical name will be required by
the complete SQL abstraction design. Therefore, we know that the
effort will not be wasted, and taking advantage of the new support
for bind variables will already require code that uses 3.3.0
version of the API to be updated.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-detailed-set-var-aft-query" id="db-api-detailed-set-var-aft-query"></a>The Bell Tolls for
<code class="computeroutput">set_variables_after_query</code>
</h3></div></div></div><p>
<code class="computeroutput">set_variables_after_query</code> is
gone! (Well, it&#39;s still there, but you&#39;ll never need to use
it.) The new API routines set local variables automatically. For
instance:</p><pre class="programlisting">

db_1row select_names "select first_names, last_name from users where user_id = [ad_conn user_id]"
doc_body_append "Hello, $first_names $last_name!"

</pre><p>Like <code class="computeroutput">ns_db 1row</code>, this will
bomb if the query doesn&#39;t return any rows (no such user
exists). If this isn&#39;t what you want, you can write:</p><pre class="programlisting">

if { [db_0or1row select_names "select first_names, last_name from users where user_id = [ad_conn user_id]"] } {
    doc_body_append "Hello, $first_names $last_name!"
} else {
    # Executed if the query returns no rows.
    doc_body_append "There&#39;s no such user!"
}

</pre><p>Selecting a bunch of rows is a lot prettier now:</p><pre class="programlisting">

db_foreach select_names "select first_names, last_name from users" {
     doc_body_append "Say hi to $first_names $last_name for me!&lt;br&gt;"
}

</pre><p>That&#39;s right, <code class="computeroutput">db_foreach</code>
is now like <code class="computeroutput">ns_db select</code> plus a
<code class="computeroutput">while</code> loop plus <code class="computeroutput">set_variables_after_query</code> plus an
<code class="computeroutput">if</code> statement (containing code
to be executed if no rows are returned).</p><pre class="programlisting">

db_foreach select_names "select first_names, last_name from users where last_name like 'S%'" {
     doc_body_append "Say hi to $first_names $last_name for me!&lt;br&gt;"
} if_no_rows {
     doc_body_append "There aren&#39;t any users with last names beginnings with S!"
}

</pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-detailed-handles" id="db-api-detailed-handles"></a>Handle Management</h3></div></div></div><p>The new API keeps track of which handles are in use, and
automatically allocates new handles when they are necessary (e.g.,
to perform subqueries while a select is active). For example:</p><pre class="programlisting">

doc_body_append "&lt;ul&gt;"
db_foreach select_names "select first_names, last_name, user_id from users" {
    # Automatically allocated a database handle from the main pool.
    doc_body_append "&lt;li&gt;User $first_names $last_name\n&lt;ul&gt;"

    db_foreach select_groups "select group_id from user_group_map where user_id = $user_id" {
        # There&#39;s a selection in progress, so we allocated a database handle
        # from the subquery pool for this selection.
        doc_body_append "&lt;li&gt;Member of group #$group_id.\n"
    } if_no_rows {
        # Not a member of any groups.
        doc_body_append "&lt;li&gt;Not a member of any group.\n"
    }
}
doc_body_append "&lt;/ul&gt;"
db_release_unused_handles

</pre><p>A new handle isn&#39;t actually allocated and released for every
selection, of course - as a performance optimization, the API keeps
old handles around until <code class="computeroutput">db_release_unused_handles</code> is invoked (or
the script terminates).</p><p>Note that there is no analogue to <code class="computeroutput">ns_db gethandle</code> - the handle is always
automatically allocated the first time it&#39;s needed.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-detailed-bindvars" id="db-api-detailed-bindvars"></a>Bind Variables</h3></div></div></div><p><span class="strong"><strong>Introduction</strong></span></p><p>Most SQL statements require that the code invoking the statement
pass along data associated with that statement, usually obtained
from the user. For instance, in order to delete a WimpyPoint
presentation, a Tcl script might use the SQL statement</p><pre class="programlisting">

delete from wp_presentations where presentation_id = <span class="emphasis"><em>some_presentation_id</em></span>
</pre><p>where <span class="emphasis"><em><code class="computeroutput">some_presentation_id</code></em></span> is a
number which is a valid presentation ID of the presentation I want
to delete. It&#39;s easy to write code handling situations like
this since SQL statements can include <span class="strong"><strong>bind variables</strong></span>, which represent
placeholders for actual data. A bind variable is specified as a
colon followed by an identifier, so the statement above can be
coded as:</p><pre class="programlisting">

db_dml presentation_delete {
    delete from wp_presentations where presentation_id = :some_presentation_id
}

</pre><p>When this SQL statement is invoked, the value for the bind
variable <code class="computeroutput">:some_presentation_id</code>
is pulled from the Tcl variable <code class="computeroutput">$some_presentation_id</code> (in the caller&#39;s
environment). Note that bind variables are not limited to one per
statement; you can use an arbitrary number, and each will pull from
the correspondingly named Tcl variable. (Alternatively, you can
also specify an list or <code class="computeroutput">ns_set</code>
providing bind variables' values; see <span class="emphasis"><em>Usage</em></span>.)</p><p>The value of a bind variable is taken literally by the database
driver, so there is never any need to put single-quotes around the
value for a bind variable, or to use <code class="computeroutput">db_quote</code> to escape single-quotes contained
in the value. The following works fine, despite the apostrophe:</p><pre class="programlisting">

set exclamation "That&#39;s all, folks!"
db_dml exclamation_insert { insert into exclamations(exclamation) values(:exclamation) }

</pre><p>Note that you can use a bind variable in a SQL statement only
where you could use a literal (a number or single-quoted string).
Bind variables cannot be placeholders for things like SQL keywords,
table names, or column names, so the following will not work, even
if <code class="computeroutput">$table_name</code> is set
properly:</p><pre class="programlisting">

select * from :table_name

</pre><p><span class="strong"><strong>Why Bind Variables Are
Useful</strong></span></p><p>Why bother with bind variables at all - why not just write the
Tcl statement above like this:</p><pre class="programlisting">

db_dml presentation_delete "
    delete from wp_presentations where presentation_id = $some_presentation_id
"

</pre><p>(Note the use of double-quotes to allow the variable reference
to <code class="computeroutput">$some_presentation_id</code> to be
interpolated in.) This will work, but consider the case where some
devious user causes <code class="computeroutput">some_presentation_id</code> to be set to something
like <code class="computeroutput">'3 or 1 = 1'</code>,
which would result in the following statement being executed:</p><pre class="programlisting">

delete from wp_presentations where presentation_id = 3 or 1 = 1

</pre><p>This deletes every presentation in the database! Using bind
variables eliminates this gaping security hole: since bind variable
values are taken literally. Oracle will attempt to delete
presentations whose presentation ID is literally <code class="computeroutput">'3 or 1 = 1'</code> (i.e., no
presentations, since <code class="computeroutput">'3 or 1 =
1'</code> can&#39;t possibly be a valid integer primary key for
<code class="computeroutput">wp_presentations</code>. In general,
since Oracle always considers the values of bind variables to be
literals, it becomes more difficult for users to perform URL
surgery to trick scripts into running dangerous queries and
DML.</p><p><span class="strong"><strong>Usage</strong></span></p><p>Every <code class="computeroutput">db_*</code> command accepting
a SQL command as an argument supports bind variables. You can
either</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>specify the <code class="computeroutput">-bind</code> switch to
provide a set with bind variable values, or</p></li><li class="listitem"><p>specify the <code class="computeroutput">-bind</code> switch to
explicitly provide a list of bind variable names and values, or</p></li><li class="listitem"><p>not specify a bind variable list at all, in which case Tcl
variables are used as bind variables.</p></li>
</ul></div><p>The default behavior (i.e., if the <code class="computeroutput">-bind</code> switch is omitted) is that these
procedures expect to find local variables that correspond in name
to the referenced bind variables, e.g.:</p><pre class="programlisting">

set user_id 123456
set role "administrator"

db_foreach user_group_memberships_by_role {
    select g.group_id, g.group_name
    from user_groups g, user_group_map map
    where g.group_id = map.user_id
    and map.user_id = :user_id
    and map.role = :role
} {
    # do something for each group of which user 123456 is in the role
    # of "administrator"
}

</pre><p>The value of the local Tcl variable <code class="computeroutput">user_id</code> (123456) is bound to the
<code class="computeroutput">user_id</code> bind variable.</p><p>The <code class="computeroutput">-bind</code> switch can takes
the name of an <code class="computeroutput">ns_set</code>
containing keys for each bind variable named in the query,
e.g.:</p><pre class="programlisting">

set bind_vars [ns_set create]
ns_set put $bind_vars user_id 123456
ns_set put $bind_vars role "administrator"

db_foreach user_group_memberships_by_role {
    select g.group_id, g.group_name
    from user_groups g, user_group_map map
    where g.group_id = map.user_id
    and map.user_id = :user_id
    and map.role = :role
} -bind $bind_vars {
    # do something for each group in which user 123456 has the role
    # of "administrator"
}

</pre><p>Alternatively, as an argument to <code class="computeroutput">-bind</code> you can specify a list of alternating
name/value pairs for bind variables:</p><pre class="programlisting">

db_foreach user_group_memberships_by_role {
    select g.group_id, g.group_name
    from user_groups g, user_group_map map
    where g.group_id = map.user_id
    and map.user_id = :user_id
    and map.role = :role
} -bind [list user_id 123456 role "administrator"] {
    # do something for each group in which user 123456 has the role
    # of "administrator"
}

</pre><p><span class="strong"><strong>
<a name="kernel.dbapi_nulls_and_bind_vars" id="kernel.dbapi_nulls_and_bind_vars"></a>Nulls and Bind
Variables</strong></span></p><p>When processing a DML statement, Oracle coerces empty strings
into <code class="computeroutput">null</code>. (This coercion does
<span class="emphasis"><em>not</em></span> occur in the
<code class="computeroutput">WHERE</code> clause of a query, i.e.
<code class="computeroutput">col = ''</code> and
<code class="computeroutput">col is null</code> are not
equivalent.)</p><p>As a result, when using bind variables, the only way to make
Oracle set a column value to <code class="computeroutput">null</code> is to set the corresponding bind
variable to the empty string, since a bind variable whose value is
the string "null" will be interpreted as the literal
string "null".</p><p>These Oracle quirks complicate the process of writing clear and
abstract DML difficult. Here is an example that illustrates
why:</p><pre class="programlisting">

#
# Given the table:
#
#   create table foo (
#           bar        integer,
#           baz        varchar(10)
#   );
#

set bar ""
set baz ""

db_dml foo_create {insert into foo(bar, baz) values(:bar, :baz)}
#
# the values of the "bar" and "baz" columns in the new row are both
# null, because Oracle has coerced the empty string (even for the
# numeric column "bar") into null in both cases

</pre><p>Since databases other than Oracle do not coerce empty strings
into <code class="computeroutput">null</code>, this code has
different semantics depending on the underlying database (i.e., the
row that gets inserted may not have null as its column values),
which defeats the purpose of SQL abstraction.</p><p>Therefore, the Database Access API provides a
database-independent way to represent <code class="computeroutput">null</code> (instead of the Oracle-specific idiom
of the empty string): <span class="strong"><strong><code class="computeroutput">db_null</code></strong></span>.</p><p>Use it instead of the empty string whenever you want to set a
column value explicitly to <code class="computeroutput">null</code>, e.g.:</p><pre class="programlisting">

set bar [db_null]
set baz [db_null]

db_dml foo_create {insert into foo(bar, baz) values(:bar, :baz)}
#
# sets the values for both the "bar" and "baz" columns to null

</pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-detailed-sql-abstraction" id="db-api-detailed-sql-abstraction"></a>SQL Abstraction</h3></div></div></div><p>We now require that each SQL statement be assigned a logical
name for the statement that is unique to the procedure or page in
which it is defined. This is so that (eventually) we can implement
logically named statements with alternative SQL for non-Oracle
databases (e.g., Postgres). More on this later.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-detailed-placing-values" id="db-api-detailed-placing-values"></a>Placing Column Values in
Arrays and Sets</h3></div></div></div><p>Normally, <code class="computeroutput">db_foreach</code>,
<code class="computeroutput">db_0or1row</code>, and <code class="computeroutput">db_1row</code> places the results of queries in
Tcl variables, so you can say:</p><pre class="programlisting">

db_foreach users_select "select first_names, last_name from users" {
    doc_body_append "&lt;li&gt;$first_names $last_name\n"
}

</pre><p>However, sometimes this is not sufficient: you may need to
examine the rows returned, to dynamically determine the set of
columns returned by the query, or to avoid collisions with existing
variables. You can use the <code class="computeroutput">-column_array</code> and <code class="computeroutput">-column_set</code> switches to <code class="computeroutput">db_foreach</code>, <code class="computeroutput">db_0or1row</code>, and <code class="computeroutput">db_1row</code> to instruct the database routines
to place the results in a Tcl array or <code class="computeroutput">ns_set</code>, respectively, where the keys are
the column names and the values are the column values. For
example:</p><pre class="programlisting">

db_foreach users_select "select first_names, last_name from users" -column_set columns {
    # Now $columns is an ns_set.
    doc_body_append "&lt;li&gt;"
    for { set i 0 } { $i &lt; [ns_set size $columns] } { incr i } {
        doc_body_append "[ns_set key $columns $i] is [ns_set value $columns $i]. \n"
    }
}

</pre><p>will write something like:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>first_names is Jon. last_name is Salz.</p></li><li class="listitem"><p>first_names is Lars. last_name is Pind.</p></li><li class="listitem"><p>first_names is Michael. last_name is Yoon.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dp-api-detailed-api" id="dp-api-detailed-api"></a>API</h3></div></div></div><p>Note that you never have to use <code class="computeroutput">ns_db</code> anymore (including <code class="computeroutput">ns_db gethandle</code>)! Just start doing stuff,
and (if you want) call <code class="computeroutput">db_release_unused_handles</code> when you&#39;re
done as a hint to release the database handle.</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_null" id="kernel.dbapi_db_null"></a>db_null</code></strong></span></span></dt><dd>
<pre class="programlisting"><span class="strong"><strong><code class="computeroutput">db_null</code></strong></span></pre><p>Returns a value which can be used in a bind variable to
represent the SQL value <code class="computeroutput">null</code>.
See <a class="link" href="db-api" title="Nulls and Bind Variables">Nulls and Bind Variables</a>
above.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_foreach" id="kernel.dbapi_db_foreach"></a>db_foreach</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_foreach</strong></span><span class="emphasis"><em>statement-name sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ] \
    [ -column_array <span class="emphasis"><em>array_name</em></span> | -column_set <span class="emphasis"><em>set_name</em></span> ] \
    <span class="emphasis"><em>code_block</em></span> [ if_no_rows <span class="emphasis"><em>if_no_rows_block ]</em></span>
</pre><p>Performs the SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>, executing <span class="emphasis"><em><code class="computeroutput">code_block</code></em></span> once for each row
with variables set to column values (or a set or array populated if
<code class="computeroutput">-column_array</code> or <code class="computeroutput">column_set</code> is specified). If the query
returns no rows, executes <span class="emphasis"><em><code class="computeroutput">if_no_rows_block</code></em></span> (if
provided).</p><p>Example:</p><pre class="programlisting">

db_foreach select_foo "select foo, bar from greeble" {
    doc_body_append "&lt;li&gt;foo=$foo; bar=$bar\n"
} if_no_rows {
    doc_body_append "&lt;li&gt;There are no greebles in the database.\n"
}

</pre><p>The code block may contain <code class="computeroutput">break</code> statements (which terminate the loop
and flush the database handle) and <code class="computeroutput">continue</code> statements (which continue to the
next row of the loop).</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_1row" id="kernel.dbapi_db_1row"></a>db_1row</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_1row</strong></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ] \
    [ -column_array <span class="emphasis"><em>array_name</em></span> | -column_set <span class="emphasis"><em>set_name</em></span> ]
</pre><p>Performs the SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>, setting variables to
column values. Raises an error if the query does not return exactly
1 row.</p><p>Example:</p><pre class="programlisting">

db_1row select_foo "select foo, bar from greeble where greeble_id = $greeble_id"
# Bombs if there&#39;s no such greeble!
# Now $foo and $bar are set.

</pre>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_0or1row" id="kernel.dbapi_db_0or1row"></a>db_0or1row</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_0or1row</strong></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ] \
    [ -column_array <span class="emphasis"><em>array_name</em></span> | -column_set <span class="emphasis"><em>set_name</em></span> ]
</pre><p>Performs the SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>. If a row is returned, sets
variables to column values and returns 1. If no rows are returned,
returns 0. If more than one row is returned, throws an error.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_string" id="kernel.dbapi_db_string"></a>db_string</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_string</strong></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -default <span class="emphasis"><em>default</em></span> ] [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]
</pre><p>Returns the first column of the result of SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>.
If <span class="emphasis"><em><code class="computeroutput">sql</code></em></span> doesn&#39;t return a row,
returns <span class="emphasis"><em><code class="computeroutput">default</code></em></span> (or throws an error if
<span class="emphasis"><em><code class="computeroutput">default</code></em></span> is unspecified).
Analogous to <code class="computeroutput">database_to_tcl_string</code> and <code class="computeroutput">database_to_tcl_string_or_null</code>.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_nextval" id="kernel.dbapi_db_nextval"></a>db_nextval</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_nextval</strong></span><span class="emphasis"><em>sequence-name</em></span>
</pre><p>Returns the next value for the sequence <span class="emphasis"><em>sequence-name</em></span> (using a SQL statement
like <code class="computeroutput">SELECT</code><span class="emphasis"><em><code class="computeroutput">sequence-name</code></em></span><code class="computeroutput">.nextval FROM DUAL</code>). If sequence pooling is
enabled for the sequence, transparently uses a value from the pool
if available to save a round-trip to the database.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_list" id="kernel.dbapi_db_list"></a>db_list</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_list</strong></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]
</pre><p>Returns a Tcl list of the values in the first column of the
result of SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>. If <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>
doesn&#39;t return any rows, returns an empty list. Analogous to
<code class="computeroutput">database_to_tcl_list</code>.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_list_of_lists" id="kernel.dbapi_db_list_of_lists"></a>db_list_of_lists</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_list_of_lists</strong></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]
</pre><p>Returns a Tcl list, each element of which is a list of all
column values in a row of the result of SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>.
If <span class="emphasis"><em><code class="computeroutput">sql</code></em></span> doesn&#39;t return any
rows, returns an empty list. (Analogous to <code class="computeroutput">database_to_tcl_list_list</code>.)</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_list_of_ns_sets" id="kernel.dbapi_db_list_of_ns_sets"></a>db_list_of_ns_sets</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_list_of_ns_sets</strong></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]
</pre><p>Returns a list of ns_sets with the values of each column of each
row returned by the <code class="computeroutput">sql</code> query
specified.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_dml" id="kernel.dbapi_db_dml"></a>db_dml</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_dml</strong></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> \
    [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ] \
    [ -blobs <span class="emphasis"><em>blob_list</em></span> | -clobs <span class="emphasis"><em>clob_list</em></span> |
      -blob_files <span class="emphasis"><em>blob_file_list</em></span> | -clob_files <span class="emphasis"><em>clob_file_list</em></span> ]
</pre><p>Performs the DML or DDL statement <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>.</p><p>If a length-<span class="emphasis"><em>n</em></span> list of
blobs or clobs is provided, then the SQL should return <span class="emphasis"><em>n</em></span> blobs or clobs into the bind variables
<code class="computeroutput">:1</code>, <code class="computeroutput">:2</code>, ... :<span class="emphasis"><em><code class="computeroutput">n</code></em></span>.
<span class="emphasis"><em><code class="computeroutput">blobs</code></em></span> or <span class="emphasis"><em><code class="computeroutput">clobs</code></em></span>, if specified, should be
a list of individual BLOBs or CLOBs to insert; <span class="emphasis"><em><code class="computeroutput">blob_files</code></em></span> or <span class="emphasis"><em><code class="computeroutput">clob_files</code></em></span>, if specified,
should be a list of <span class="emphasis"><em>paths to
files</em></span> containing the data to insert. Only one of
<code class="computeroutput">-blobs</code>, <code class="computeroutput">-clobs</code>, <code class="computeroutput">-blob_files</code>, and <code class="computeroutput">-clob_files</code> may be provided.</p><p>Example:</p><pre class="programlisting">

db_dml insert_photos {
        insert photos(photo_id, image, thumbnail_image)
        values(photo_id_seq.nextval, empty_blob(), empty_blob())
        returning image, thumbnail_image into :1, :2
    } -blob_files [list "/var/tmp/the_photo" "/var/tmp/the_thumbnail"] 

</pre><p>This inserts a new row into the <code class="computeroutput">photos</code> table, with the contents of the
files <code class="computeroutput">/var/tmp/the_photo</code> and
<code class="computeroutput">/var/tmp/the_thumbnail</code> in the
<code class="computeroutput">image</code> and <code class="computeroutput">thumbnail</code> columns, respectively.</p>
</dd><dt><span class="term">
<span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_write_clob" id="kernel.dbapi_db_write_clob"></a>db_write_clob</code></strong></span>,
<span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_write_blob" id="kernel.dbapi_db_write_blob"></a>db_write_blob</code></strong></span>,
<span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_blob_get_file" id="kernel.dbapi_db_blob_get_file"></a>db_blob_get_file</code></strong></span>
</span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_write_clob</strong></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]

<span class="strong"><strong>db_write_blob</strong></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]

<span class="strong"><strong>db_blob_get_file</strong></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]
</pre><p>Analogous to <code class="computeroutput">ns_ora
write_clob/write_blob/blob_get_file</code>.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_release_unused_handles" id="kernel.dbapi_db_release_unused_handles"></a>db_release_unused_handles</code></strong></span></span></dt><dd>
<pre class="programlisting"><span class="strong"><strong>db_release_unused_handles</strong></span></pre><p>Releases any allocated, unused database handles.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_transaction" id="kernel.dbapi_db_transaction"></a>db_transaction</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_transaction</strong></span><span class="emphasis"><em>code_block</em></span> [ on_error { <span class="emphasis"><em>code_block</em></span> } ]
</pre><p>Executes <span class="emphasis"><em><code class="computeroutput">code_block</code></em></span> transactionally.
Nested transactions are supported (<code class="computeroutput">end
transaction</code> is transparently <code class="computeroutput">ns_db dml</code>'ed when the outermost
transaction completes). The <code class="computeroutput">db_abort_transaction</code> command can be used to
abort all levels of transactions. It is possible to specify an
optional <code class="computeroutput">on_error</code> code block
that will be executed if some code in <span class="emphasis"><em>code_block</em></span> throws an exception. The
variable <code class="computeroutput">errmsg</code> will be bound
in that scope. If there is no <code class="computeroutput">on_error</code> code, any errors will be
propagated.</p><p>Example:</p><pre class="programlisting">

proc replace_the_foo { col } {
    db_transaction {
        db_dml delete {delete from foo}
        db_dml insert {insert into foo(col) values($col)}
    }
}

proc print_the_foo {} {
    doc_body_append "foo is [db_string "select col from foo"]&lt;br&gt;\n"
}

replace_the_foo 8
print_the_foo ; # Writes out "foo is 8"

db_transaction {
    replace_the_foo 14
    print_the_foo ; # Writes out "foo is 14"
    db_dml insert_foo {insert into some_other_table(col) values(999)}
    ...
    db_abort_transaction
} on_error {
    doc_body_append "Error in transaction: $errmsg"
}
    

print_the_foo ; # Writes out "foo is 8"

</pre>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_abort_transaction" id="kernel.dbapi_db_abort_transaction"></a>db_abort_transaction</code></strong></span></span></dt><dd>
<pre class="programlisting"><span class="strong"><strong>db_abort_transaction</strong></span></pre><p>Aborts all levels of a transaction. That is if this is called
within several nested transactions, all of them are terminated. Use
this instead of <code class="computeroutput">db_dml
"abort" "abort transaction"</code>.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_multirow" id="kernel.dbapi_db_multirow"></a>db_multirow</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_multirow</strong></span> [ -local ] [ -append ] [ -extend <span class="emphasis"><em>column_list</em></span> ] \
    <span class="emphasis"><em>var-name</em></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> \
    [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ] \
    <span class="emphasis"><em>code_block</em></span> [ if_no_rows <span class="emphasis"><em>if_no_rows_block ]</em></span>
</pre><p>Performs the SQL query <code class="computeroutput">sql</code>,
saving results in variables of the form <code class="computeroutput">
<span class="replaceable"><span class="replaceable">var_name</span></span>:1</code>, <code class="computeroutput">
<span class="replaceable"><span class="replaceable">var_name</span></span>:2</code>, etc, setting
<code class="computeroutput">
<span class="replaceable"><span class="replaceable">var_name</span></span>:rowcount</code> to the total
number of rows, and setting <code class="computeroutput">
<span class="replaceable"><span class="replaceable">var_name</span></span>:columns</code> to a list of
column names.</p><p>Each row also has a column, rownum, automatically added and set
to the row number, starting with 1. Note that this will override
any column in the SQL statement named 'rownum', also if
you&#39;re using the Oracle rownum pseudo-column.</p><p>If the <code class="computeroutput">-local</code> is passed, the
variables defined by db_multirow will be set locally (useful if
you&#39;re compiling dynamic templates in a function or similar
situations).</p><p>You may supply a code block, which will be executed for each row
in the loop. This is very useful if you need to make computations
that are better done in Tcl than in SQL, for example using
ns_urlencode or ad_quotehtml, etc. When the Tcl code is executed,
all the columns from the SQL query will be set as local variables
in that code. Any changes made to these local variables will be
copied back into the multirow.</p><p>You may also add additional, computed columns to the multirow,
using the <code class="computeroutput">-extend { <span class="replaceable"><span class="replaceable">col_1</span></span><span class="replaceable"><span class="replaceable">col_2</span></span> ... }</code> switch. This is
useful for things like constructing a URL for the object retrieved
by the query.</p><p>If you&#39;re constructing your multirow through multiple
queries with the same set of columns, but with different rows, you
can use the <code class="computeroutput">-append</code> switch.
This causes the rows returned by this query to be appended to the
rows already in the multirow, instead of starting a clean multirow,
as is the normal behavior. The columns must match the columns in
the original multirow, or an error will be thrown.</p><p>Your code block may call <code class="computeroutput">continue</code> in order to skip a row and not
include it in the multirow. Or you can call <code class="computeroutput">break</code> to skip this row and quit
looping.</p><p>Notice the nonstandard numbering (everything else in Tcl starts
at 0); the reason is that the graphics designer, a non programmer,
may wish to work with row numbers.</p><p>Example:</p><pre class="programlisting">
db_multirow -extend { user_url } users users_query {
    select user_id first_names, last_name, email from cc_users
} {
    set user_url [acs_community_member_url -user_id $user_id]
}
    
</pre>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_resultrows" id="kernel.dbapi_db_resultrows"></a>db_resultrows</code></strong></span></span></dt><dd>
<pre class="programlisting"><span class="strong"><strong>db_resultrows</strong></span></pre><p>Returns the number of rows affected or returned by the previous
statement.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_with_handle" id="kernel.dbapi_db_with_handle"></a>db_with_handle</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_with_handle</strong></span><span class="emphasis"><em>var</em></span><span class="emphasis"><em>code_block</em></span>
</pre><p>Places a database handle into the variable <span class="emphasis"><em><code class="computeroutput">var</code></em></span>
and executes <span class="emphasis"><em><code class="computeroutput">code_block</code></em></span>. This is useful when
you don&#39;t want to have to use the new API (<code class="computeroutput">db_foreach</code>, <code class="computeroutput">db_1row</code>, etc.), but need to use database
handles explicitly.</p><p>Example:</p><pre class="programlisting">

proc lookup_the_foo { foo } {
    db_with_handle db {
        return [db_string unused "select ..."]
    }
}

db_with_handle db {
    # Now there&#39;s a database handle in $db.
    set selection [ns_db select $db "select foo from bar"]
    while { [ns_db getrow $db $selection] } {
        set_variables_after_query

        lookup_the_foo $foo
    }
}

</pre>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_name" id="kernel.dbapi_db_name"></a>db_name</code></strong></span></span></dt><dd>
<pre class="programlisting"><span class="strong"><strong><code class="computeroutput">db_name</code></strong></span></pre><p>Returns the name of the database, as returned by the driver.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_type" id="kernel.dbapi_db_type"></a>db_type</code></strong></span></span></dt><dd>
<pre class="programlisting"><span class="strong"><strong><code class="computeroutput">db_type</code></strong></span></pre><p>Returns the RDBMS type (i.e. oracle, postgresql) this OpenACS
installation is using. The nsv ad_database_type is set up during
the bootstrap process.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_compatible_rdbms_p" id="kernel.dbapi_db_compatible_rdbms_p"></a>db_compatible_rdbms_p</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_compatible_rdbms_p</strong></span> db_type
                
</pre><p>Returns 1 if the given db_type is compatible with the current
RDBMS.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_package_supports_rdbms_p" id="kernel.dbapi_db_package_supports_rdbms_p"></a>db_package_supports_rdbms_p</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_package_supports_rdbms_p</strong></span> db_type_list
                
</pre><p>Returns 1 if db_type_list contains the current RDMBS type. A
package intended to run with a given RDBMS must note this in
it&#39;s package info file regardless of whether or not it actually
uses the database.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_legacy_package_p" id="kernel.dbapi_db_legacy_package_p"></a>db_legacy_package_p</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_legacy_package_p</strong></span> db_type_list
                
</pre><p>Returns 1 if the package is a legacy package. We can only tell
for certain if it explicitly supports Oracle 8.1.6 rather than the
OpenACS more general oracle.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_version" id="kernel.dbapi_db_version"></a>db_version</code></strong></span></span></dt><dd>
<pre class="programlisting"><span class="strong"><strong>db_version</strong></span></pre><p>Returns the RDBMS version (i.e. 8.1.6 is a recent Oracle
version; 7.1 a recent PostgreSQL version.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_current_rdbms" id="kernel.dbapi_db_current_rdbms"></a>db_current_rdbms</code></strong></span></span></dt><dd>
<pre class="programlisting"><span class="strong"><strong>db_current_rdbms</strong></span></pre><p>Returns the current rdbms type and version.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="kernel.dbapi_db_known_database_types" id="kernel.dbapi_db_known_database_types"></a>db_known_database_types</code></strong></span></span></dt><dd>
<pre class="programlisting"><span class="strong"><strong>db_known_database_types</strong></span></pre><p>Returns a list of three-element lists describing the database
engines known to OpenACS. Each sublist contains the internal
database name (used in file paths, etc), the driver name, and a
"pretty name" to be used in selection forms displayed to
the user.</p><p>The nsv containing the list is initialized by the bootstrap
script and should never be referenced directly by user code.
Returns the current rdbms type and version.</p>
</dd>
</dl></div><div class="cvstag">($&zwnj;Id: db-api.xml,v 1.11.2.3 2017/04/21 15:07:53
gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="apm-design" leftLabel="Prev" leftTitle="Package Manager Design"
		    rightLink="i18n-requirements" rightLabel="Next" rightTitle="OpenACS Internationalization
Requirements"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		