<master>
<property name=title>@title@</property>
<property name="context">@context@</property>

<if @error_msg@ ne "">
@error_msg@
</if>
<else>
<table width="100%">
  <tr><td bgcolor="#e4e4e4">@documentation@</td></tr>
</table>

<if @source_p@ eq 0>
[ <a href="proc-view?proc=@proc@&amp;source_p=1">show source</a> ]
</if>
<else>
[ <a href="proc-view?proc=@proc@&amp;source_p=0">hide source</a> ]
</else>

<if @source_p@ ne @default_source_p@> 
 | [ <a href="set-default?source_p=@source_p@&amp;return_url=@return_url@">make this
the default</a> ]
</if>
</else>

<form action=proc-view method=get>
Show another procedure: <input type="text" name="proc"> <input type="submit" value="Go">
</form>

