
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System API: Database Query}</property>
<property name="doc(title)">Templating System API: Database Query</property>
<master>
<h2>Database Query</h2>
<strong>
<a href="../index">Templating System</a> : API
Reference</strong>
<h3>Summary</h3>
<p>Utilize the results of a database query as a template data
source.</p>
<h3>Method</h3>
<pre>
query <em>name structure sql -db dbhandle 
                             -startrow n 
                             -maxrows n
                             -bind (set|list)
                             -eval { code }</em>
</pre>
<p>Perform a query and store the results in a local variable.</p>
<h3>Examples</h3>
<pre>
set db [ns_db gethandle]

# this will set a scalar named current_time
template::query current_time onevalue "select sysdate from dual" -db $db

# this will set a single array named user_info with a key for each column
template::query user_info onerow "select * from users 
                                  where user_id = 86" -db $db

# this will set an array for <em>each</em> row returned by the query
# the arrays will be named user_info:1, user_info:2, etc.
# the variable user_info:rowcount will be set with the total number of rows.
template::query user_info multirow "select * from users" -db $db

# this will set a list named emails
template::query emails onelist "select email from users" -db $db

# this will set a list of lists named user_info
template::query user_info multilist "select * from users" -db $db

# this will create a nested list of lists in the form
# { California { Berkeley { { Ralph Smith } { Doug Jones } } } \
#   Minnestota { Minneapolis { { Ina Jaffe } { Silvia Pojoli } } } }
template::query persons nestedlist "
  select state, city, first_name, last_name from users" \
  -db $db -groupby { state city }
</pre>
<h3>Note(s)</h3>
<ul>
<li>Valid values for <kbd>structure</kbd> are <kbd>onevalue,
onerow, multirow, onelist, nestedlist and multilist.</kbd>
</li><li>
<kbd>sql</kbd> may be any valid SQL statement whose result set
has the appropriate dimensions for the desired
<kbd>structure</kbd>.</li><li>The <kbd>db</kbd> parameter is optional. If no parameter is
supplied, a handle will be requested to perform the query and then
released immediately.</li><li>The <kbd>startrow</kbd> and <kbd>maxrows</kbd> parameters are
valid only for multirow queries. They may be specified to limit the
rows from the query result that are included in the data
source.</li><li>The <kbd>eval</kbd> parameter takes a block of Tcl code to
perform on each row of a multirow query as it is fetched from the
database. The code may refer to the <kbd>row</kbd> array to get and
set column values.</li><li>The <kbd>bind</kbd> option is valid only when using
Oracle.</li>
</ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->