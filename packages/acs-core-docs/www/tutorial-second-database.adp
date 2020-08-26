
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Connect to a second database}</property>
<property name="doc(title)">Connect to a second database</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="tutorial-upgrade-scripts" leftLabel="Prev"
			title="Chapter 10. Advanced
Topics"
			rightLink="tutorial-future-topics" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-second-database" id="tutorial-second-database"></a>Connect to a second database</h2></div></div></div><p>It is possible to use the OpenACS Tcl database API with other
databases. In this example, the OpenACS site uses a PostGre
database, and accesses another PostGre database called legacy.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>Modify config.tcl to accommodate the legacy database, and to
ensure that the legacy database is not used for standard OpenACS
queries:</p><pre class="programlisting">ns_section ns/db/pools
ns_param   pool1              "Pool 1"
ns_param   pool2              "Pool 2"
ns_param   pool3              "Pool 3"
ns_param   legacy             "Legacy"

ns_section ns/db/pool/pool1
<span class="emphasis"><em>#Unchanged from default</em></span>
ns_param   maxidle            1000000000
ns_param   maxopen            1000000000
ns_param   connections        5
ns_param   verbose            $debug
ns_param   extendedtableinfo  true
ns_param   logsqlerrors       $debug
if { $database eq "oracle" } {
    ns_param   driver             ora8
    ns_param   datasource         {}
    ns_param   user               $db_name
    ns_param   password           $db_password
} else {
    ns_param   driver             postgres
    ns_param   datasource         ${db_host}:${db_port}:${db_name}
    ns_param   user               $db_user
    ns_param   password           ""
}

ns_section ns/db/pool/pool2
<span class="emphasis"><em>#Unchanged from default, removed for clarity</em></span>

ns_section ns/db/pool/pool3
<span class="emphasis"><em>#Unchanged from default, removed for clarity</em></span>

ns_section ns/db/pool/legacy
ns_param   maxidle            1000000000
ns_param   maxopen            1000000000
ns_param   connections        5
ns_param   verbose            $debug
ns_param   extendedtableinfo  true
ns_param   logsqlerrors       $debug
ns_param   driver             postgres
ns_param   datasource         ${db_host}:${db_port}:legacy_db
ns_param   user               legacy_user
ns_param   password           legacy_password


ns_section ns/server/${server}/db
ns_param   pools              *
ns_param   defaultpool        pool1

ns_section ns/server/${server}/acs/database
ns_param database_names [list main legacy]
ns_param pools_main [list pool1 pool2 pool3]
ns_param pools_legacy [list legacy]</pre>
</li><li class="listitem">
<p>To use the legacy database, use the <code class="code">-dbn</code> flag for any of the <code class="code">db_</code> API calls. For example, suppose there is a table
called "foo" in the legacy system, with a field
"bar". List "bar" for all records with this Tcl
file:</p><pre class="programlisting">db_foreach -dbn legacy get_bar_query {
  select bar from foo
  limit 10
} {
  ns_write "&lt;br/&gt;$bar"
}</pre>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="tutorial-upgrade-scripts" leftLabel="Prev" leftTitle="Writing upgrade scripts"
			rightLink="tutorial-future-topics" rightLabel="Next" rightTitle="Future Topics"
			homeLink="index" homeLabel="Home" 
			upLink="tutorial-advanced" upLabel="Up"> 
		    