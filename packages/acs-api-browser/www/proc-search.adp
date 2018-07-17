<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<div style="float: right;">
  <include src="/packages/acs-api-browser/lib/search" query_string="@query_string;literal@">
</div>

<div style="float: left; width: 60%;">
<h3>Procedure Matches</h3>
<ul>
  <multiple name="results">
  <li> <if @results.score@ lt 10>&nbsp;&nbsp;</if>@results.score@: <a href="@results.url@">@results.proc@</a>
   <em>@results.args;noquote@</em>
   </multiple>
</ul>

<if @results:rowcount;literal@ eq 0>
No results found
</if>


<if @private_results:rowcount;literal@ gt 0>
  <if @show_private_p;literal@ true>
    <p>
      <strong>Show</strong> | <a href="@hide_private_url@">Hide</a> <strong>@private_results:rowcount@ private</strong> procedure matches
    </p>
    <ul>
      <multiple name="private_results">
        <li><if @private_results.score@ lt 10>&nbsp;&nbsp;</if>@private_results.score@: <a href="@private_results.url@">@private_results.proc@</a>
         <em>@private_results.args;noquote@</em>
       </multiple>
    </ul>
  </if>
  <else>
    <p>
      <a href="@show_private_url@">Show</a> | <strong>Hide</strong> <strong>@private_results:rowcount@ private</strong> procedure matches
    </p>
  </else>
</if>


<if @deprecated_results:rowcount;literal@ gt 0>
  <if @show_deprecated_p;literal@ true>
    <p>
      <strong>Show</strong> | <a href="@hide_deprecated_url@">Hide</a> <strong>@deprecated_results:rowcount@ deprecated</strong> procedure matches
    </p>
    <ul>
      <multiple name="deprecated_results">
        <li><if @deprecated_results.score@ lt 10>&nbsp;&nbsp;</if>@deprecated_results.score@: <a href="@deprecated_results.url@">@deprecated_results.proc@</a>
         <em>@deprecated_results.args;noquote@</em>
       </multiple>
    </ul>
  </if>
  <else>
    <p>
      <a href="@show_deprecated_url@">Show</a> | <strong>Hide</strong> <strong>@deprecated_results:rowcount@ deprecated</strong> procedure matches
    </p>
  </else>
</if>
<br style="clear:both">
</div>


