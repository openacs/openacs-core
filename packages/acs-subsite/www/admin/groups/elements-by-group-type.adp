<if @group_types:rowcount@ eq 0>
  <ul>
  <li>#acs-subsite.none#</li>
  </ul>
</if>
<else>

<ul>  
<multiple name="group_types">
 <li><a href="../group-types/one?group_type=@group_types.group_type_enc@">@group_types.type_pretty_name@</a>
 <ul>
 <if @group_types.number_groups@ lt 25>
   <include ds="0" src="../group-types/groups-list" group_type="@group_types.group_type;literal@">
 </if>
 <else>
   <li> <a href="../group-types/groups-display?group_type=@group_types.group_type_enc@">View all @group_types.number_groups@ groups</a></li>
   </else>
 </ul>
 </li>  
</multiple>

</ul>

</else>
