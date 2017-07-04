<table border="0" cellspacing="12" cellpadding="4"> 
 <tr style="background:#DDDDDD">
  <td>
    <form action="@openacs_search_url@" method="get">
     <table>
     <tr>
      <td valign="top">
       <h4>OpenACS Tcl API Search</h4>
       <div>
       <input type="text" name="query_string" value="@query_string@"><br>
       <input type="submit" value="All matches" name="search_type">
       <input type="submit" value="Only best match" name="search_type">
       <if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if>
       </div>
       <p><a href="@openacs_browse_url@">Browse OpenACS Tcl API</a></p>
      </td>
      <td>       
       <table cellspacing="0" cellpadding="0">
         <tr><td align="right">Name contains:</td>
           <td><input type="radio" name="name_weight" value="5" checked="checked"> </td>
         </tr>
         <tr><td align="right">Exact name:</td>
           <td><input type="radio" name="name_weight" value="exact"></td>
         </tr>
         <tr><td align="right">&nbsp;</td><td>&nbsp;</td></tr>
         <tr><td align="right">Parameters:</td>
           <td><input type="checkbox" name="param_weight" value="3" checked="checked"></td>
         </tr>
         <tr><td align="right">Documentation:</td>
           <td><input type="checkbox" name="doc_weight" value="2" checked="checked"></td>
         </tr>
         <tr><td align="right">Source:</td>
           <td><input type="checkbox" name="source_weight" value="1"></td>
         </tr>
       </table>
      </td>
     </tr>
    </table>
   </form>
  </td>
 </tr>
 
 <tr style="background:#DDDDDD">
  <td colspan="2">
   <h4>OpenACS PL/SQL API Search</h4>
   <p><a href="@openacs_plsql_browse_url@">Browse OpenACS PL/SQL API</a></p>
  </td>
 </tr>

  <tr style="background:#DDDDDD">
   <td colspan="2">
    <form action="@aolserver_search_url@" method="get">
    <h4>NaviServer/AOLserver Tcl API Search</h4>
    <div>
    <input type="text" name="tcl_proc">
    <input type="submit" value="Go"><br>
    <if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if>
    (enter <em>exact</em> procedure name)<br>
    <a href="@server_tcl_api_root@">Browse NaviServer Tcl API</a>
    </div>
     </form>
   </td>
  </tr>

  <tr style="background:#DDDDDD">
   <td colspan="2">
    <form action="@tcl_search_url@" method="get">
    <h4>Tcl Documentation Search</h4>
    <div>
    <input type="text" name="tcl_proc">
    <if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if>
    <input type="submit" value="Go"><br>
    (enter <em>exact</em> procedure name)<br>
    <a href="@tcl_docs_root@">Browse the Tcl documentation</a>
    </div>
     </form>
   </td>
  </tr>


   <tr style="background:#DDDDDD">
    <td colspan="2">
     <if @db_doc_search_url@ not nil>
     <form action="@db_doc_search_url@" method="get">
   	@db_doc_search_export;noquote@
       <h4>@db_pretty@ Search</h4>
       <div>
       <input type="text" name="@db_doc_search_query_name@">
       <input type="submit" value="Go"><br>
       </div>
     </if>
     <else>
       <h4>@db_pretty@ Documentation</h4>
     </else>
     <p><a href="@db_doc_url@">Browse the @db_pretty@ documentation</a>
      <if @db_doc_search_url@ not nil>
      </form>
    </td>
   </tr>
 </if>

  <tr style="background:#DDDDDD">
   <td colspan="2">
    <h4>OpenACS and Package Documentation</h4>
    <a href="/doc">Browse OpenACS documentation</a>
   </td>
  </tr>
  
  <tr style="background:#DDDDDD">
   <td colspan="2">
    <h4>Deprecated Functions</h4>
    <a href="@package_url@/deprecated">List Deprecated Functions</a>
   </td>
  </tr>
</table>
