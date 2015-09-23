
<property name="context">{/doc/acs-core-docs {Documentation}} {Constraint naming standard}</property>
<property name="doc(title)">Constraint naming standard</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="eng-standards-versioning" leftLabel="Prev"
		    title="
Chapter 12. Engineering Standards"
		    rightLink="eng-standards-filenaming" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="eng-standards-constraint-naming" id="eng-standards-constraint-naming"></a>Constraint naming
standard</h2></div></div></div><div class="authorblurb">
<p>By Michael Bryzek</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-constraint-naming-big-picture" id="eng-standards-constraint-naming-big-picture"></a>The Big
Picture</h3></div></div></div><p>Constraint naming standard is important for one reason: The
SYS_* name oracle assigns to unnamed constraints is not very
understandable. By correctly naming all contraints, we can quickly
associate a particular constraint with our data model. This gives
us two real advantages:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>We can quickly identify and fix any errors.</p></li><li class="listitem"><p>We can reliabily modify or drop constraints</p></li>
</ul></div><div>Why do we need a naming convention?</div><p>
<a class="ulink" href="http://oradoc.photo.net/ora8doc/DOC/server803/A54647_01/ch2.htm#2956" target="_top">Oracle limits names</a>, in general, to 30
characters, which is hardly enough for a human readable constraint
name.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-constraint-naming-abbr" id="eng-standards-constraint-naming-abbr"></a>Abbreviations</h3></div></div></div><p>We propose the following naming convention for all constraints,
with the following abbreviations taken from Oracle Docs at
<a class="ulink" href="http://oradoc.photo.net/ora81/DOC/server.815/a67779/ch4e.htm#8953" target="_top">http://oradoc.photo.net/ora81/DOC/server.815/a67779/ch4e.htm#8953</a>.
Note that we shortened all of the constraint abbrevations to two
characters to save room.</p><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col><col>
</colgroup><thead><tr>
<th>Constraint type</th><th>Abbreviation</th>
</tr></thead><tbody>
<tr>
<td>references (foreign key)</td><td>fk</td>
</tr><tr>
<td>unique</td><td>un</td>
</tr><tr>
<td>primary key</td><td>pk</td>
</tr><tr>
<td>check</td><td>ck</td>
</tr><tr>
<td>not null</td><td>nn</td>
</tr>
</tbody>
</table></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-constraint-naming-format" id="eng-standards-constraint-naming-format"></a>Format of
constraint name</h3></div></div></div><p>&lt;table name&gt;_&lt;column_name&gt;_&lt;constraint
abbreviation&gt;</p><p>In reality, this won't be possible because of the character
limitation on names inside oracle. When the name is too long, we
will follow these two steps in order:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Abbreviate the table name with the table's initials (e.g. users
-&gt; u and users_contact -&gt; uc).</p></li><li class="listitem"><p>Truncate the column name until it fits.</p></li>
</ol></div><p>If the constraint name is still too long, you should consider
rewriting your entire data model :)</p><p><span class="strong"><strong>Notes:</strong></span></p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>If you have to abbreviate the table name for one of the
constraints, abbreviate it for all the constraints</p></li><li class="listitem"><p>If you are defining a multi column constraint, try to truncate
the two column names evenly</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-constraint-naming-example" id="eng-standards-constraint-naming-example"></a>Example</h3></div></div></div><pre class="programlisting">
create table example_topics (
       topic_id    integer
                   constraint example_topics_topic_id_pk
                   primary key
);

create table constraint_naming_example (
       example_id                     integer
                                      constraint cne_example_id_pk
                                      primary key,
       one_line_description           varchar(100)
                                      constraint cne_one_line_desc_nn
                                      not null,
       body                           clob,
       up_to_date_p                   char(1) default('t')
                                      constraint cne_up_to_date_p_check
                                      check(up_to_date_p in ('t','f')),
       topic_id                       constraint cne_topic_id_nn not null
                                      constraint cne_topic_id_fk references example_topics,
       -- Define table level constraint
       constraint cne_example_id_one_line_unq unique(example_id, one_line_description)
);

</pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-constraint-naming-pk" id="eng-standards-constraint-naming-pk"></a>Why it's good to name
primary keys</h3></div></div></div><p>Naming primary keys might not have any obvious advantages.
However, here's an example where naming the primary key really
helps (and this is by no means a rare case!</p><pre class="programlisting">
SQL&gt; set autotrace traceonly explain;


SQL&gt; select * from constraint_naming_example, example_topics 
where constraint_naming_example.topic_id = example_topics.topic_id;

Execution Plan
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=CHOOSE
   1    0   NESTED LOOPS
   2    1     TABLE ACCESS (FULL) OF 'CONSTRAINT_NAMING_EXAMPLE'
   3    1     INDEX (UNIQUE SCAN) OF 'EXAMPLE_TOPICS_TOPIC_ID_PK' (UNI
          QUE)
</pre><p>Isn't it nice to see "EXAMPLE_TOPICS_TOPIC_ID_PK" in the trace
and know exactly which table oracle is using at each step?</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-constraint-naming-nn" id="eng-standards-constraint-naming-nn"></a>Naming not null
constraints is optional...</h3></div></div></div><p>People disagree on whether or not we should be naming not null
constraints. So, if you want to name them, please do so and follow
the above naming standard. But, naming not null constraints is not
a requirement.</p><div>About Naming the not null constraints</div><p>Though naming "not null" constraints doesn't help immeditately
in error debugging (e.g. the error will say something like "Cannot
insert null value into column"), we recommend naming not null
constraints to be consistent in our naming of all constraints.</p><div class="cvstag">($Id: constraint-naming.xml,v 1.6 2006/07/17
05:38:37 torbenb Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="eng-standards-versioning" leftLabel="Prev" leftTitle="Release Version Numbering"
		    rightLink="eng-standards-filenaming" rightLabel="Next" rightTitle="ACS File Naming and Formatting
Standards"
		    homeLink="index" homeLabel="Home" 
		    upLink="eng-standards" upLabel="Up"> 
		