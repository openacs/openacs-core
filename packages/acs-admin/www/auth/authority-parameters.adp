<master>
  <property name="context">@context;noquote@</property>
  <property name="title">@page_title;noquote@</property>

<if @has_parameters_p@>
  <formtemplate id="parameters" style="configuration"></formtemplate>
</if>
<else>
  The selected driver implementation has no parameters to configure.
</else>
