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
