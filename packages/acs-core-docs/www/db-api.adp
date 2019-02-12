
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {The OpenACS Database Access API}</property>
<property name="doc(title)">The OpenACS Database Access API</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="request-processor" leftLabel="Prev"
			title="Chapter 11. Development
Reference"
			rightLink="templates" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="db-api" id="db-api"></a>The OpenACS Database Access API</h2></div></div></div><p>By Pete Su and Jon Salz. Modified by Roberto Mello.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-overview" id="db-api-overview"></a>Overview</h3></div></div></div><p>One of OpenACS&#39;s great strengths is that code written for it
is very close to the database. It is very easy to interact with the
database from anywhere within OpenACS, and we have a coherent API
for database access which makes this even easier.</p><p>More detailed information about the DB API is available at
<a class="xref" href="db-api-detailed" title="Database Access API">Database Access API</a>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-examples" id="db-api-examples"></a>DB API Examples</h3></div></div></div><p>The OpenACS database API is meant to save developers from making
common mistakes and to provide a more structured syntax for
specifying database operations, including transactions. Here&#39;s
an example of the API.</p><pre class="programlisting">
set count 0
set tcl_var "foo"
set sql {
        SELECT foo, bar, baz
       FROM some_table, some_other_table
       WHERE some_table.id = some_other_table.id
         and some_table.condition_p = :tcl_var
}

db_transaction {
    db_foreach my_example_query_name $sql {
        lappend rows [list $foo $bar $baz]
        incr count
    }
    foreach row $rows { 
        call_some_proc $foo $bar $baz
    }
}</pre><p>There are several things to note here:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>No explicit code for grabbing and releasing handles. Usage of
the Database API implicitly deals with all handle management
issues.</p></li><li class="listitem"><p>The <code class="computeroutput">db_transaction</code> command
makes the scope of a transaction clear; <code class="computeroutput">db_transaction</code> takes the code block
argument and automatically runs it in the context of a transaction.
If you use something like db_foreach though, you need to make sure
that there are no calls in the code block which would take a second
db handle since the transaction is only valid for one handle (thats
why we build up a list of returned values and call a second proc
outside the db_foreach loop).</p></li><li class="listitem"><p>The command <code class="computeroutput">db_foreach</code>
writes our old while loop for us.</p></li><li class="listitem"><p>Every SQL query has a name, which is used in conjunction with
.XQL files to support multiple databases.</p></li><li class="listitem"><p>Finally and most importantly, there API implements bind
variables, which we will cover next.</p></li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-bindvariables" id="db-api-bindvariables"></a>Bind Variables</h3></div></div></div><p>Bind variables are placeholders for literal values in an SQL
query being sent to the server. In the old way, data was generally
passed to directly to the DB backend, via Tcl string interpolation.
In the example above, the query would look like:</p><pre class="programlisting">
select foo, bar, baz 
from some_table, some_other_table
where some_table.id=some_other_table.id  
and some_table.condition_p = '$foo'</pre><p>There are a few problems with this:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>If the value of $foo is a huge string, then we waste a lot of
time in the database server doing useless parsing.</p></li><li class="listitem"><p>Second, if the literal value contains characters like single
quotes, we have to be careful to properly escape them, because not
quoting them will lead to surprising errors.</p></li><li class="listitem">
<p>Third, no type checking occurs on the literal value. Finally, if
the Tcl variable is passed in or between web forms or otherwise
subject to external modification, there is nothing keeping
malicious users from setting the Tcl variable to some string that
changes the query textually. This type of attack, called
<span class="emphasis"><em>SQL smuggling</em></span>, can be very
damaging - entire tables can be exposed or have their contents
deleted, for example.</p><p>Another very important reason for using bind variables is
performance. Oracle can cache previously parsed queries. If there
are values in the where clause, that is how the query is cached. It
also performs bind variable susbstitution after parsing the SQL
statement. This means that SQL statements that use bind variables
will always match (assuming all else is the same) while SQL
statements that do not use bind variables will not match unless the
values in the statement are exactly the same. This will improve the
query cache considerably, which can make the server much more
efficient.</p>
</li>
</ol></div><p>What the DB API (in conjuntion with the database drivers
implemented for aolserver) do is send the SQL statement to the
server for parsing, then <span class="emphasis"><em>bind</em></span> values to the variables and sends
those values along separately as a second step. This separate
binding step is where the term <span class="emphasis"><em>bind
variable</em></span> comes from.</p><p>This split has several advantages. First, type checking happens
on the literal. If the column we are comparing against holds
numbers, and we send a string, we get a nice error. Second, since
string literals are no longer in the query, no extra quoting is
required. Third, substitution of bind variables cannot change the
actual text of the query, only the literal values in the
placeholders. The database API makes bind variables easy to use by
hooking them smoothly into the Tcl runtime so you simply provide
:tclvar and the value of $tclvar is sent to the backend to actually
execute the query.</p><p>The database API parses the query and pulls out all the bind
variable specifications and replaces them with generic
placeholders. It then automatically pulls the values of the named
Tcl vars out of the runtime environment of the script, and passes
them to the database.</p><p>Note that while this looks like a simple syntactic change, it
really is very different from how interpolated text queries work.
You use bind variables to replace what would otherwise be a literal
value in a query, and Tcl style string interpolation does not
happen. So you cannot do something like:</p><pre class="programlisting">
set table "baz"
set condition "where foo = bar"

db_foreach my_query { select :table from some_table where :condition }
    </pre><p>SQL will not allow a literal to occur where we&#39;ve put the
bind variables, so the query is syntactically incorrect. You have
to remember that while the bind variable syntax looks similar to
variable interpolation in Tcl, It is <span class="emphasis"><em>not
the same thing at all</em></span>.</p><p>Finally, the DB API has several different styles for passing
bind variable values to queries. In general, use the style
presented here because it is the most convenient.</p><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="db-api-bind-vars-usage" id="db-api-bind-vars-usage"></a>Usage</h4></div></div></div><p>Every <code class="computeroutput">db_*</code> command accepting
a SQL command as an argument supports bind variables. You can
either</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Specify the <code class="computeroutput">-bind</code> switch to
provide a set with bind variable values, or</p></li><li class="listitem"><p>Specify the <code class="computeroutput">-bind</code> switch to
explicitly provide a list of bind variable names and values, or</p></li><li class="listitem"><p>Not specify a bind variable list at all, in which case Tcl
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

      </pre>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="dbapi_nulls_and_bind_vars" id="dbapi_nulls_and_bind_vars"></a>Nulls and Bind Variables</h4></div></div></div><p>When processing a DML statement, Oracle coerces empty strings
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

db_dml foo_create "insert into foo(bar, baz) values(:bar, :baz)"
#
# the values of the "bar" and "baz" columns in the new row are both
# null, because Oracle has coerced the empty string (even for the
# numeric column "bar") into null in both cases

      </pre>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-pooling" id="db-api-pooling"></a>Sequence Pooling</h3></div></div></div><p>The database library can transparently maintain pools of
sequence values, so that each request for a new sequence value
(using <code class="computeroutput">db_nextval</code>) does not
incur a roundtrip to the server. For instance, this functionality
is very useful in the security/sessions library, which very
frequently allocates values from the <code class="computeroutput">sec_id_seq</code> sequence. To utilize this
functionality for a particular sequence, register the sequence to
be pooled, either using the <code class="computeroutput">db_register_pooled_sequence</code> procedure at
server startup time, or by including a configuration parameter of
the form</p><pre class="programlisting">

PoolSequence.<span class="emphasis"><em>sequence_name_seq</em></span>=<span class="emphasis"><em>count</em></span>
</pre><p>in <span class="emphasis"><em>any</em></span> configuration
section in the <code class="computeroutput">yourservername.ini</code> file, e.g.,</p><pre class="programlisting">

[ns/server/<span class="emphasis"><em>yourservername</em></span>/acs/security]
PoolSequence.sec_id_seq=20

    </pre><p>The database library will allocate this number of sequence
values at server startup. It will periodically scan pools and
allocate new values for sequences which are less than half-full.
(This normally occurs every 60 seconds, and is configurable via the
<code class="computeroutput">PooledSequenceUpdateInterval</code>
parameter in the <code class="computeroutput">[ns/server/</code><span class="emphasis"><em><code class="computeroutput">yourservername</code></em></span><code class="computeroutput">/acs/database]</code> configuration section.)</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-basicapi" id="db-api-basicapi"></a>Basic API</h3></div></div></div><p>The Database API has several functions that wrap familiar parts
of the AOLserver database API.</p><p>Note that you never have to use <code class="computeroutput">ns_db</code> anymore (including <code class="computeroutput">ns_db gethandle</code>)! Just start doing stuff,
and (if you want) call <code class="computeroutput">db_release_unused_handles</code> when you&#39;re
done as a hint to release the database handle.</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_abort_transaction" id="devguide.dbapi_db_abort_transaction"></a>db_abort_transaction</code></span></dt><dd>
<pre class="programlisting">
db_abort_transaction
          </pre><p>Aborts all levels of a transaction. That is if this is called
within several nested transactions, all of them are terminated. Use
this instead of <code class="computeroutput">db_dml
"abort" "abort transaction"</code>.</p>
</dd><dt><span class="term"><span class="strong"><strong><code class="computeroutput">
<a name="devguide.dbapi_db_multirow" id="devguide.dbapi_db_multirow"></a>db_multirow</code></strong></span></span></dt><dd>
<pre class="programlisting">
<span class="strong"><strong>db_multirow</strong></span> [ -local ] [ -append ] [ -extend <span class="emphasis"><em>column_list</em></span> ] \
    <span class="emphasis"><em>var-name</em></span><span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> \
    [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ] \
    <span class="emphasis"><em>code_block</em></span> [ if_no_rows <span class="emphasis"><em>if_no_rows_block ]</em></span>
</pre><p>Performs the SQL query <code class="computeroutput">sql</code>,
saving results in variables of the form <code class="computeroutput">
<em class="replaceable"><code>var_name</code></em>:1</code>, <code class="computeroutput">
<em class="replaceable"><code>var_name</code></em>:2</code>, etc, setting
<code class="computeroutput">
<em class="replaceable"><code>var_name</code></em>:rowcount</code> to the
total number of rows, and setting <code class="computeroutput">
<em class="replaceable"><code>var_name</code></em>:columns</code> to a list
of column names.</p><p>Each row also has a column, rownum, automatically added and set
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
using the <code class="computeroutput">-extend { <em class="replaceable"><code>col_1</code></em><em class="replaceable"><code>col_2</code></em> ... }</code> switch. This is
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
    </pre><p>You can also iterate over a multirow after it has been created -
check the documentation for template::multirow</p><p>For example,</p><pre class="programlisting">
db_multirow assets assets {
  select asset_id,
    from ...
}

..

set asset_id_l [list]
multirow foreach assets {
  lappend asset_id_l $asset_id
}
          </pre><p>Technically it&#39;s equivalent to using a code block on the end
of your db_multirow.</p>
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_foreach" id="devguide.dbapi_db_foreach"></a>db_foreach</code></span></dt><dd>
<pre class="programlisting">
db_foreach <span class="emphasis"><em>statement-name sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ] \
    [ -column_array <span class="emphasis"><em>array_name</em></span> | -column_set <span class="emphasis"><em>set_name</em></span> ] \
    <span class="emphasis"><em>code_block</em></span> [ if_no_rows <span class="emphasis"><em>if_no_rows_block ]</em></span>
</pre><p>Performs the SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span> , executing <span class="emphasis"><em><code class="computeroutput">code_block</code></em></span> once for each row
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
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_1row" id="devguide.dbapi_db_1row"></a>db_1row</code></span></dt><dd>
<pre class="programlisting">
db_1row <span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ] \
    [ -column_array <span class="emphasis"><em>array_name</em></span> | -column_set <span class="emphasis"><em>set_name</em></span> ]
          </pre><p>Performs the SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>, setting variables to
column values. Raises an error if the query does not return exactly
1 row.</p><p>Example:</p><pre class="programlisting">

db_1row select_foo "select foo, bar from greeble where greeble_id = $greeble_id"
# Bombs if there&#39;s no such greeble!
# Now $foo and $bar are set.

          </pre>
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_0or1row" id="devguide.dbapi_db_0or1row"></a>db_0or1row</code></span></dt><dd>
<pre class="programlisting">
db_0or1row <span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ] \
    [ -column_array <span class="emphasis"><em>array_name</em></span> | -column_set <span class="emphasis"><em>set_name</em></span> ]
          </pre><p>Performs the SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>. If a row is returned, sets
variables to column values and returns 1. If no rows are returned,
returns 0. If more than one row is returned, throws an error.</p>
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_nextval" id="devguide.dbapi_db_nextval"></a>db_nextval</code></span></dt><dd>
<pre class="programlisting">
db_nextval <span class="emphasis"><em>sequence-name</em></span>
</pre><p>Returns the next value for the sequence <span class="emphasis"><em>sequence-name</em></span> (using a SQL statement
like <code class="computeroutput">SELECT</code><span class="emphasis"><em><code class="computeroutput">sequence-name</code></em></span><code class="computeroutput">.nextval FROM DUAL</code>). If sequence pooling is
enabled for the sequence, transparently uses a value from the pool
if available to save a round-trip to the database (see <span class="emphasis"><em><a class="xref" href="db-api" title="Sequence Pooling">Sequence Pooling</a></em></span>).</p>
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_register_pooled_sequence" id="devguide.dbapi_db_register_pooled_sequence"></a>db_register_pooled_sequence</code></span></dt><dd>
<pre class="programlisting">
db_register_pooled_sequence <span class="emphasis"><em>sequence-name</em></span><span class="emphasis"><em>pool-size</em></span>
</pre><p>Registers the sequence <span class="emphasis"><em>sequence-name</em></span> to be pooled, with a pool
size of <span class="emphasis"><em>pool-size</em></span> sequence
values (see <span class="emphasis"><em><a class="xref" href="db-api" title="Sequence Pooling">Sequence
Pooling</a></em></span>).</p>
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_string" id="devguide.dbapi_db_string"></a>db_string</code></span></dt><dd>
<pre class="programlisting">
db_string <span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -default <span class="emphasis"><em>default</em></span> ] [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]
          </pre><p>Returns the first column of the result of SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>.
If <span class="emphasis"><em><code class="computeroutput">sql</code></em></span> doesn&#39;t return a row,
returns <span class="emphasis"><em><code class="computeroutput">default</code></em></span> (or throws an error if
<span class="emphasis"><em><code class="computeroutput">default</code></em></span> is unspecified).
Analogous to <code class="computeroutput">database_to_tcl_string</code> and <code class="computeroutput">database_to_tcl_string_or_null</code>.</p>
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_list" id="devguide.dbapi_db_list"></a>db_list</code></span></dt><dd>
<pre class="programlisting">
db_list <span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]
          </pre><p>Returns a Tcl list of the values in the first column of the
result of SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>. If <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>
doesn&#39;t return any rows, returns an empty list. Analogous to
<code class="computeroutput">database_to_tcl_list</code>.</p>
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_list_of_lists" id="devguide.dbapi_db_list_of_lists"></a>db_list_of_lists</code></span></dt><dd>
<pre class="programlisting">
db_list_of_lists <span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]
          </pre><p>Returns a Tcl list, each element of which is a list of all
column values in a row of the result of SQL query <span class="emphasis"><em><code class="computeroutput">sql</code></em></span>.
If <span class="emphasis"><em><code class="computeroutput">sql</code></em></span> doesn&#39;t return any
rows, returns an empty list. (Analogous to <code class="computeroutput">database_to_tcl_list_list</code>.)</p>
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_dml" id="devguide.dbapi_db_dml"></a>db_dml</code></span></dt><dd>
<pre class="programlisting">
db_dml <span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> \
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
    }  -blob_files [list "/var/tmp/the_photo" "/var/tmp/the_thumbnail"] 

          </pre><p>This inserts a new row into the <code class="computeroutput">photos</code> table, with the contents of the
files <code class="computeroutput">/var/tmp/the_photo</code> and
<code class="computeroutput">/var/tmp/the_thumbnail</code> in the
<code class="computeroutput">image</code> and <code class="computeroutput">thumbnail</code> columns, respectively.</p>
</dd><dt><span class="term">
<code class="computeroutput">
<a name="devguide.dbapi_db_write_clob" id="devguide.dbapi_db_write_clob"></a>db_write_clob</code>,
<code class="computeroutput">
<a name="devguide.dbapi_db_write_blob" id="devguide.dbapi_db_write_blob"></a>db_write_blob</code>,
<code class="computeroutput">
<a name="devguide.dbapi_db_blob_get_file" id="devguide.dbapi_db_blob_get_file"></a>db_blob_get_file</code>
</span></dt><dd>
<pre class="programlisting">
db_write_clob <span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]

db_write_blob <span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]

db_blob_get_file <span class="emphasis"><em>statement-name</em></span><span class="emphasis"><em>sql</em></span> [ -bind <span class="emphasis"><em>bind_set_id</em></span> | -bind <span class="emphasis"><em>bind_value_list</em></span> ]
          </pre><p>Analogous to <code class="computeroutput">ns_ora
write_clob/write_blob/blob_get_file</code>.</p>
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_release_unused_handles" id="devguide.dbapi_db_release_unused_handles"></a>db_release_unused_handles</code></span></dt><dd>
<pre class="programlisting">
            db_release_unused_handles
          </pre><p>Releases any allocated, unused database handles.</p>
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_transaction" id="devguide.dbapi_db_transaction"></a>db_transaction</code></span></dt><dd>
<pre class="programlisting">
db_transaction <span class="emphasis"><em>code_block</em></span> [ on_error { <span class="emphasis"><em>code_block</em></span> } ]
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
        db_dml insert {insert into foo(col) values(:col)}
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
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_resultrows" id="devguide.dbapi_db_resultrows"></a>db_resultrows</code></span></dt><dd>
<pre class="programlisting">
db_resultrows
          </pre><p>Returns the number of rows affected or returned by the previous
statement.</p>
</dd><dt><span class="term"><code class="computeroutput">
<a name="devguide.dbapi_db_with_handle" id="devguide.dbapi_db_with_handle"></a>db_with_handle</code></span></dt><dd>
<pre class="programlisting">
db_with_handle <span class="emphasis"><em>var</em></span><span class="emphasis"><em>code_block</em></span>
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
</dd>
</dl></div><p><span class="cvstag">($&zwnj;Id: db-api.xml,v 1.14 2017/08/07 23:47:54
gustafn Exp $)</span></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-api-caching" id="db-api-caching"></a>Caching Database API Results</h3></div></div></div><p>The database API allows for direct caching of query results.
Repeated calls will return the cached value until it is either
explicitly flushed using db_flush_cache, times out (configured the
ns_cache is called to create the cache), or another cached query
fills the cache, causing older entries to be flushed.</p><p>Values returned by a query are cached if you pass the
"-cache_key" switch to the database procedure. The switch
value will be used as the key in the ns_cache eval call used to
execute the query and processing code. The db_flush proc should be
called to flush the cache when appropriate. The
"-cache_pool" parameter can be used to specify the cache
pool to be used, and defaults to db_cache_pool. The size of the
default cache is governed by the kernel parameter
"DBCacheSize" in the "caching" section.</p><p>Currently db_string, db_list, db_list_of_lists, db_1row,
db_0or1row, and db_multirow support caching.</p><p>For caching to be effective, one must carefully design a
cache_pool and cache_key strategy that uniquely identifies a query
within the system, including the relevant objects being referenced
by the query. Typically a cache_key should include one or more
object_ids and a name that identifies the operation being done.</p><p>Here is an example from the layout-manager package:</p><pre class="programlisting">

# Query to return the elements of a page as a list. The prefix "page_" is used to denote
# that this is a page-related query, page_id is used to uniquely identify the query
# by object, and the suffix uniquely defines the operation being performed on the
# page object.

db_list -cache_key page_${page_id}_get_elements get_elements {}

# When the contents of a page are changed, we flush all page-related queries for the given
# page object using db_flush_cache.

db_flush_cache -cache_key_pattern page_${page_id}_*

    </pre>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="request-processor" leftLabel="Prev" leftTitle="The Request Processor"
			rightLink="templates" rightLabel="Next" rightTitle="Using Templates in OpenACS"
			homeLink="index" homeLabel="Home" 
			upLink="dev-guide" upLabel="Up"> 
		    
