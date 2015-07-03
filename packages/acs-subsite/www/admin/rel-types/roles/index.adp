<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Roles</property>

<ul>
  <if @roles:rowcount@ eq 0>
    <li> <em>(none)</em>
  </if><else>
  <multiple name="roles">
    <li> <a href="one?role=<%=[ad_urlencode $roles(role)]%>">@roles.pretty_name@ (@roles.role@)</a>
  </multiple>
  </else>

  <p><li> <a href="new">Create a role</a>
</ul>

