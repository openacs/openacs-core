<master>
<property name=title>@title@</property>

<h2>@title@</h2>

@context_bar@

<hr>

<h3>Deprecated Procedures:</h3>
<ul>
<multiple name="deprecated">
<li><a
 href=proc-view?proc=@deprecated.proc@>@deprecated.proc@</a> <i>@deprecated.args@</i>
 </multiple>
 </ul>

<if @deprecated:rowcount@ eq 0>
 No deprecated procedures found
 </if>