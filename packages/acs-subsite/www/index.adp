<master src="master">
<property name="context_bar">@context_bar@</property>
<property name="title">@subsite_name@</property>

<ul>

 <if @nodes:rowcount@ eq 0> 
  <li> (no packages)</li>
 </if>
 <else>
  <multiple name="nodes">
    <li><a href="@nodes.url@">@nodes.name@</a></li>
  </multiple>
 </else>

 <if @admin_p@ eq 1> 
  <p><li> <a href="admin/">Administration</a></li>
 </if>

</ul>
