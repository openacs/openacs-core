<master>
<property name=title>Erase Portrait</property>

<h2>Erase Portrait</h2>

@context_bar@

<hr>

<if @admin_p@ eq 0>
  Are you sure that you want to erase your portrait?
</if>
<else>
  Are you sure that you want to erase this user's portrait?
</else>

<center>
<form method=GET action="erase-2">
@export_vars@
<input type=submit value="Yes, I'm sure">
</center>

