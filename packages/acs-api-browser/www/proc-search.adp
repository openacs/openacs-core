<master>
<property name=title>@title@</property>
<property name="context">@context@</property>

<h3>Procedure Matches:</h3>
<ul>
  <multiple name="results">
  <li> <if @results.score@ lt 10>&nbsp;&nbsp;</if>@results.score@: <a href=@results.url@>@results.proc@</a>
   <i>@results.args@</i>
   </multiple>
</ul>

<if @results:rowcount@ eq 0>
No results found
</if>

<form action=proc-search method=get>
<table bgcolor=#DDDDDD cellpadding=15 border=0 cellspacing=0>
  <tr><td valign=top>
   <b>ACS API Search:</b><br>
   <input type=text name=query_string value="@query_string@"><br>
   <input type=submit value=Search name=search_type>
   <input type=submit value="Feeling Lucky" name=search_type>
   </td>
  <td><table cellspacing=0 cellpadding=0>
    <font size=-1>
    <tr>
      <td align=right>Name:</td>
       <if @name_weight@ eq 0>
      <td><input type=checkbox name=name_weight value=5> </td>
       </if>
       <else>
      <td><input type=checkbox name=name_weight value=5 checked> </td>
       </else>
    </tr>
    <tr>
      <td align=right>Parameters:</td>
       <if @param_weight@ eq 0>
      <td><input type=checkbox name=param_weight value=5> </td>
       </if>
       <else>
      <td><input type=checkbox name=param_weight value=5 checked> </td>
       </else>
    </tr>
    <tr>
      <td align=right>Documentation:</td>
       <if @doc_weight@ eq 0>
      <td><input type=checkbox name=doc_weight value=5> </td>
       </if>
       <else>
      <td><input type=checkbox name=doc_weight value=5 checked> </td>
       </else>
    </tr>
    <tr>
      <td align=right>Source:</td>
       <if @source_weight@ eq 0>
      <td><input type=checkbox name=source_weight value=5> </td>
       </if>
       <else>
      <td><input type=checkbox name=source_weight value=5 checked> </td>
       </else>
    </tr>
    </font>
 </table>
 </td>
</tr>
</form>
</table>
