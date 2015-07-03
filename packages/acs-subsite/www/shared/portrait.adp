<master>
<property name="&doc">doc</property>
<property name="context">@context;literal@</property>

<div style="padding: 1em; text-align: center;">
  <img @widthheight_param@ src="@subsite_url@shared/portrait-bits.tcl?@export_vars@" alt="#acs-subsite.lt_Portrait_of_first_last#">
  <if @description@ ne "">
    <p>@description@</p>
  </if>
</div>
