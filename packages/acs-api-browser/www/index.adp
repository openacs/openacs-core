<master>
<property name=title>@title@</property>
<property name=context_bar>@context_bar@</property>

<table align="right" border="0" cellspacing="0" cellpadding="0" bgcolor="#DDDDDD"> 
 <tr>
  <td>
   <form action="proc-search" method="get">
   <table>
    <tr>
     <td valign="top">
      <h4>ACS Tcl API Search:</h4>

      <input type="text" name="query_string"><br>
      <input type="submit" value="Search" name="search_type">
      <input type="submit" value="Feeling Lucky" name="search_type"><p>
      <a href="proc-browse">Browse OpenACS Tcl API</a>

     </td>
     <td>
      <table cellspacing="0" cellpadding="0">
        <tr><td align=right>Name:</td>
          <td><input type="checkbox" name="name_weight" value="5" checked> </td>
        <tr><td align=right>Parameters:</td>
          <td><input type="checkbox" name="param_weight" value="3" checked></td>
        <tr><td align=right>Documentation:</td>
          <td><input type="checkbox" name="doc_weight" value="2" checked></td>
        <tr><td align=right>Source:</td>
          <td><input type="checkbox" name="source_weight" value="1"></td>
        </tr>
      </table>
     </td>
    </tr>
   </table>
   </form>

   <hr>
    <h4>ACS PL/SQL API Search:</h4>
    <a href="plsql-subprograms-all">Browse OpenACS PL/SQL API</a>
    <p>

    <form action="tcl-proc-view" method="get">
     <h4>AOLserver API Search:</h4><br>
     <input type="text" name="tcl_proc">
     <input type="submit" value="Go"><br>
     (enter <em>exact</em> procedure name)<br>
     <a href="@aolserver_tcl_api_root@">Browse AOLserver Tcl API</a>
    </form>

    <p>

    <h4>Tcl Documentation Search:</h4>
    <form action="tcl-doc-search" method="get">
     <input type="text" name="tcl_proc">
     <input type="submit" value="Go"><br>
     (enter <em>exact</em> procedure name)<br>
     <a href="@tcl_docs_root@">Browse the Tcl documentation</a>
    </form>

   </td>
  </tr>
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

