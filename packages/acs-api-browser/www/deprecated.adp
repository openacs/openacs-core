<master>
<property name=title>@title@</property>
<property name=context_bar>@context_bar@</property>

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