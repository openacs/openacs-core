<master>
<property name=title>@title;noquote@</property>
<property name="context">@context;noquote@</property>

<if @error_msg@ ne "">
@error_msg;noquote@
</if>
<else>
<table width="100%">
  <tr><td bgcolor="#eeeeee">@documentation;noquote@</td></tr>
</table>

<if @source_p@ eq 0>
[ <a href="proc-view?proc=@proc@&amp;source_p=1&amp;version_id=@version_id@">show source</a> ]
</if>
<else>
[ <a href="proc-view?proc=@proc@&amp;source_p=0&amp;version_id=@version_id@">hide source</a> ]
</else>

<if @source_p@ ne @default_source_p@> 
 | [ <a href="set-default?source_p=@source_p@&amp;return_url=@return_url@">make this
the default</a> ]
</if>
</else>

<form action=proc-view method=get>
Show another procedure: <input type="text" name="proc"> <input type="submit" value="Go">
</form>

