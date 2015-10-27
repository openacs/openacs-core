<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<if @error_msg@ ne "">
@error_msg;noquote@
</if>
<else>
<table width="100%">
  <tr><td style="background: #eeeeee">@documentation;literal@</td></tr>
</table>

<if @source_p@ eq 0>
[ <a href="@procViewToggleURL;noi18n@">show source</a> ]
</if>
<else>
[ <a href="@procViewToggleURL;noi18n@">hide source</a> ]
</else>

<if @source_p@ ne @default_source_p@> 
 | [ <a href="@setDefaultURL;noi18n@">make this the default</a> ]
</if>
</else>

<form action="proc-view" method="get">
<div>Show another procedure: <input type="text" name="proc"> <input type="submit" value="Go"></div>
</form>

