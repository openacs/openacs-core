<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>
  <property name="focus">@focus;literal@</property>

<if @global_param_url@ defined>
<h2>Global parameters</h2> 
<blockquote>
<p><a href='@global_param_url@'>@global_parameter_label@</a></p>
</blockquote>
<h2>Instance parameters</h2>
</if>
<if @counter@ gt 0>
  <formtemplate id="parameters"></formtemplate>

  <if @display_warning_p;literal@ true>
    <span style="color: red; font-weight: bold;">(*)</span>
    #acs-subsite.lt_Note_text_in_red_below#
  </if>

</if>
<else>
  <p> #acs-subsite.No_package_parameters# </p>
  <if @return_url@ not nil>
    <p> <strong>&raquo;</strong> <a href="@return_url@">#acs-subsite.Go_back#</a> </p>
  </if>
</else>

