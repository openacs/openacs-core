<master>
<property name="context">@context;noquote@</property>
<property name="title">Roles</property>

<ul>
  <if @roles:rowcount@ eq 0>
    <li> <em>(none)</em>
  </if><else>
  <multiple name="roles">
    <li> <a href=one?role=<%=[ad_urlencode $roles(role)]%>>@roles.pretty_name@ (@roles.role@)</a>
  </multiple>
  </else>

  <p><li> <a href=new>Create a role</a>
</ul>

