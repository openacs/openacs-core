<master>
<property name="title">@subsite_name;noquote@</property>
<property name="context">@context;noquote@</property>

<ul>
 <if @nodes:rowcount@ eq 0> 
  <li>(no packages)</li>
 </if>
 <else>
  <multiple name="nodes">
    <li><a href="@nodes.url@">@nodes.name@</a></li>
  </multiple>
 </else>

 <if @admin_p@ eq 1> 
  <p>
   <li> <a href="admin/">@subsite_name@ Administration</a></li>
  </p>
 </if>
</ul>

