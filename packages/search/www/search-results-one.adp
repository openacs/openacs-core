<if @title_summary@ nil>
  <a href=@url@>Untitled</a><br>
</if>
<else>
  <a href=@url@>@title_summary;noquote@</a><br>
</else>
<if @txt_summary@ nil>
</if>
<else>
@txt_summary;noquote@<br>
</else>
<font color=green>@url@</font><br><br>