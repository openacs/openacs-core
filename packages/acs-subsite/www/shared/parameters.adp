<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>
  <property name="focus">@focus;noquote@</property>

<if @counter@ gt 0>
  <formtemplate id="parameters"></formtemplate>

  <if @display_warning_p@ true>
    <span style="color: red; font-weight: bold;">(*)</span>
    Note text in red below the parameter entry fields indicates the value of this
    parameter is being overridden by an entry in the OpenACS parameter file.  The
    use of the parameter file is discouraged but some sites need it to provide
    instance-specific values for parameters independent of the apm_parameter
    tables.
  </if>

</if>
<else>
  <p> This package does not have any parameters. </p>
  <if @return_url@ not nil>
    <p> <b>&raquo;</b> <a href="@return_url@">Go back</a> </p>
  </if>
</else>
