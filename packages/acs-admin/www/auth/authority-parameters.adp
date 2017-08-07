<master>
  <property name="context">@context;literal@</property>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="focus">parameters.@first_param_name;noquote@</property>

<if @has_parameters_p;literal@ true>
  <formtemplate id="parameters"></formtemplate>
</if>
<else>
  The selected driver implementation has no parameters to configure.
</else>
