<master>
<property name="title">Erase Portrait</property>
<property name="context">@context@</property>

<if @admin_p@ eq 0>
  <p>Are you sure that you want to erase your portrait?</p>
</if>
<else>
  <p>Are you sure that you want to erase this user's portrait?</p>
</else>

<form method="get" action="erase-2">
@export_vars@
<center>
<input type="submit" value="Yes, I'm sure" />
</center>

