<master>
<property name=title>@title;noquote@</property>
<property name="context">@context;noquote@</property>

<div style="float: right;">
  <include src="/packages/acs-api-browser/lib/search" query_string="@query_string@">
</div>

<h3>Procedure Matches:</h3>
<ul>
  <multiple name="results">
  <li> <if @results.score@ lt 10>&nbsp;&nbsp;</if>@results.score@: <a href=@results.url@>@results.proc@</a>
   <i>@results.args;noquote@</i>
   </multiple>
</ul>

<if @results:rowcount@ eq 0>
No results found
</if>


<if @deprecated_results:rowcount@ gt 0>
  <if @show_deprecated_p@ true>
    <p>
      <b>Show</b> | <a href="@hide_deprecated_url@">Hide</a> deprecated procedure matches
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
      <a href="@show_deprecated_url@">Show</a> | <b>Hide</b> deprecated procedure matches
    </p>
  </else>
</if>
