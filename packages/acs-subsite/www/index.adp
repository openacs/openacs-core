<master>
<property name="title">@subsite_name@</property>
<property name="context">@context@</property>

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

<if @user_id@ eq 0><a href="@login_url@">Login</a></if>
<else><a href="register/logout">Logout</a></else>
