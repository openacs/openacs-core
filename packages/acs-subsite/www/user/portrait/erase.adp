<master>
<property name="title">#acs-subsite.Erase_Portrait#</property>
<property name="context">@context;noquote@</property>

<if @admin_p@ eq 0>
  <p>#acs-subsite.lt_Sure_erase_your_por#</p>
</if>
<else>
  <p>#acs-subsite.lt_Sure_erase_user_por#</p>
</else>

<form method="get" action="erase-2">
@export_vars;noquote@
<center>
<input type="submit" value="#acs-subsite.Yes_I_am_sure#" />
</center>


