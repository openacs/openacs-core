<master>
<property name="title">#acs-subsite.Application_Error#</property>
<property name="context">#acs-subsite.Error#</property>

<if @custom_message@ nil>
#acs-subsite.lt_We_had_a_problem_proc#
</if>
<else>
@custom_message@
</else>

