<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>
  <property name="focus">@focus;noquote@</property>

<if @counter@ gt 0>
  <formtemplate id="parameters"></formtemplate>

  <if @display_warning_p@ true>
    <span style="color: red; font-weight: bold;">(*)</span>
    #acs-subsite.lt_Note_text_in_red_below#
  </if>

</if>
<else>
  <p> #acs-subsite.No_package_parameters# </p>
  <if @return_url@ not nil>
    <p> <b>&raquo;</b> <a href="@return_url@">#acs-subsite.Go_back#</a> </p>
  </if>
</else>

