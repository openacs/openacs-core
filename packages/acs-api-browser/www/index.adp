<master>
<property name=title>@title@</property>

<h2>@title@</h2>

@context_bar@

<hr>
<table align=right border=0 cellspacing=0 cellpadding=15 bgcolor=#DDDDDD> 

<tr><td>
<form action=proc-search method=get>
<table><tr><td valign=top>
   <b>ACS Tcl API Search:</b><br>
   <input type=text name=query_string><br>
   <input type=submit value=Search name=search_type>
   <input type=submit value="Feeling Lucky" name=search_type><br>
   <a href=proc-browse>Browse OpenACS Tcl API</a><br>

 </td>
 <td><font size=-1>
     <table cellspacing=0 cellpadding=0>
      <tr><td align=right>Name:</td>
          <td><input type=checkbox name=name_weight value=5 checked> </td>
      <tr><td align=right>Parameters:</td>
          <td><input type=checkbox name=param_weight value=3 checked></td>
      <tr><td align=right>Documentation:</td>
          <td><input type=checkbox name=doc_weight value=2 checked></td>
      <tr><td align=right>Source:</td>
          <td><input type=checkbox name=source_weight value=1></td>
      </tr></font>
      </table>
 </td>
</form></table>

  <h4>ACS PL/SQL API Search:</h4>
  <a href="plsql-subprograms-all">Browse OpenACS PL/SQL API</a>

  <p>

  <form action=tcl-proc-view method=get>
  <b>AOLserver API Search:</b><br>
  <input type=text name=tcl_proc>
  <input type=submit value=Go><br>
  (enter <em>exact</em> procedure name)<br>
  <a href="@aolserver_tcl_api_root@">Browse AOLserver Tcl API</a>
  </form>

</td>
</tr>
</form>
</td>
</table>


<h3>Installed Enabled Packages</h3>
<ul>
  
<multiple name="installed_packages">
  <li><a
   href="package-view?version_id=@installed_packages.version_id@">@installed_packages.pretty_name@
   @installed_packages.version_name@</a>
</multiple>

</ul>

<h3>Disabled Packages</h3>

<ul>

<multiple name="disabled_packages">
  <li>@disabled_packages.pretty_name@ @disabled_packages.version_name@</a>
</multiple>

</ul>

<h3>Uninstalled Packages</h3>

<ul>

<multiple name="uninstalled_packages">
  <li>@uninstalled_packages.pretty_name@ @uninstalled_packages.version_name@</a>
</multiple>

</ul>
