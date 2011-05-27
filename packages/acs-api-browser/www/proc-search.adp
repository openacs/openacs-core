<master>
<property name=title>@title;noquote@</property>
<property name="context">@context;noquote@</property>

<div style="float: right;">
  <include src="/packages/acs-api-browser/lib/search" query_string="@query_string@">
</div>

<div style="float: left; width: 60%;">
<h3>Procedure Matches</h3>
<ul>
  <multiple name="results">
  <li> <if @results.score@ lt 10>&nbsp;&nbsp;</if>@results.score@: <a href=@results.url@>@results.proc@</a>
   <i>@results.args;noquote@</i>
   </multiple>
</ul>

<if @results:rowcount@ eq 0>
No results found
</if>


<if @private_results:rowcount@ gt 0>
  <if @show_private_p@ true>
    <p>
      <b>Show</b> | <a href="@hide_private_url@">Hide</a> <b>@private_results:rowcount@ private</b> procedure matches
    </p>
    <ul>
      <multiple name="private_results">
        <li><if @private_results.score@ lt 10>&nbsp;&nbsp;</if>@private_results.score@: <a href=@private_results.url@>@private_results.proc@</a>
         <i>@private_results.args;noquote@</i>
       </multiple>
    </ul>
  </if>
  <else>
    <p>
      <a href="@show_private_url@">Show</a> | <b>Hide</b> <b>@private_results:rowcount@ private</b> procedure matches
    </p>
  </else>
</if>


<if @deprecated_results:rowcount@ gt 0>
  <if @show_deprecated_p@ true>
    <p>
      <b>Show</b> | <a href="@hide_deprecated_url@">Hide</a> <b>@deprecated_results:rowcount@ deprecated</b> procedure matches
    </p>
    <ul>
      <multiple name="deprecated_results">
        <li><if @deprecated_results.score@ lt 10>&nbsp;&nbsp;</if>@deprecated_results.score@: <a href=@deprecated_results.url@>@deprecated_results.proc@</a>
         <i>@deprecated_results.args;noquote@</i>
       </multiple>
    </ul>
  </if>
  <else>
    <p>
      <a href="@show_deprecated_url@">Show</a> | <b>Hide</b> <b>@deprecated_results:rowcount@ deprecated</b> procedure matches
    </p>
  </else>
</if>
<br clear="both">
</div>


