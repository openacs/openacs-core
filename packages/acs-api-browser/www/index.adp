<master>
<property name=title>@title@</property>
<property name="context">@context@</property>

<table align="right" border="0" cellspacing="12" cellpadding="4"> 
 <tr bgcolor="#DDDDDD">
  <td>
   <table>

    <form action="proc-search" method="get">
     <tr>
      <td valign="top">
       <h4>OpenACS Tcl API Search</h4>
       <input type="text" name="query_string" /><br />
       <input type="submit" value="All matches" name="search_type" />
       <input type="submit" value="Only best match" name="search_type" />
       <p><a href="proc-browse">Browse OpenACS Tcl API</a></p>
      </td>
      <td>       
       <table cellspacing="0" cellpadding="0">
         <tr><td align="right">Name contains:</td>
           <td><input type="radio" name="name_weight" value="5" checked="checked" /> </td></tr>
         <tr><td align="right">Exact name:</td>
           <td><input type="radio" name="name_weight" value="exact" /></td></tr>
         <tr><td align="right">&nbsp;</td><td>&nbsp;</td></tr>
         <tr><td align="right">Parameters:</td>
           <td><input type="checkbox" name="param_weight" value="3" checked="checked" /></td></tr>
         <tr><td align="right">Documentation:</td>
           <td><input type="checkbox" name="doc_weight" value="2" checked="checked" /></td></tr>
         <tr><td align="right">Source:</td>
           <td><input type="checkbox" name="source_weight" value="1" /></td></tr>
       </table>
      </td>
     </tr>
    </form>
   </table>
  </td>
 </tr>
 
 <tr bgcolor="#DDDDDD">
  <td colspan="2">
   <h4>OpenACS PL/SQL API Search</h4>
   <p><a href="plsql-subprograms-all">Browse OpenACS PL/SQL API</a></p>
  </td>
 </tr>

 <form action="tcl-proc-view" method="get">
  <tr bgcolor="#DDDDDD">
   <td colspan="2">
    <h4>AOLserver API Search</h4>
    <input type="text" name="tcl_proc" />
    <input type="submit" value="Go" /><br />
    (enter <em>exact</em> procedure name)<br />
    <a href="@aolserver_tcl_api_root@">Browse AOLserver Tcl API</a>
   </td>
  </tr>
 </form>

 <form action="tcl-doc-search" method="get">
  <tr bgcolor="#DDDDDD">
   <td colspan="2">
    <h4>Tcl Documentation Search</h4>
    <input type="text" name="tcl_proc" />
    <input type="submit" value="Go" /><br />
    (enter <em>exact</em> procedure name)<br />
    <a href="@tcl_docs_root@">Browse the Tcl documentation</a>
   </td>
  </tr>
 </form>

</table>


<h3>Installed Enabled Packages</h3>
<ul>
  
<multiple name="installed_packages">
  <li><a
   href="package-view?version_id=@installed_packages.version_id@">@installed_packages.pretty_name@
   @installed_packages.version_name@</a></li>
</multiple>

</ul>

<h3>Disabled Packages</h3>


<if @disabled_packages:rowcount@ eq 0>
 <b>NONE</b>  
</if>
<else>
 <multiple name="disabled_packages">
  <ul>
   <li>@disabled_packages.pretty_name@ @disabled_packages.version_name@</a>
  </ul>
 </multiple>
</else>


<h3>Uninstalled Packages</h3>

<if @uninstalled_packages:rowcount@ eq 0>
<b>NONE</b>
</if>
<else>
 <multiple name="uninstalled_packages">
  <ul>
   <li>@uninstalled_packages.pretty_name@ @uninstalled_packages.version_name@</a>
  </ul>
 </multiple>
</else>

