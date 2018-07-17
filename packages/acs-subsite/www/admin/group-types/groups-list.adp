<if @groups:rowcount;literal@ eq 0>
  <li>(none)</li>
</if>
<else>
 <multiple name="groups">
  <li> <a href="../groups/one?group_id=@groups.group_id@">@groups.group_name@</a> </li>
 </multiple>
</else>
