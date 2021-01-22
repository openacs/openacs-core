<master>
<property name="&doc">doc</property>
<property name="context">@context;literal@</property>

<if @admin_p;literal@ false>
  <p>#acs-subsite.lt_Sure_erase_your_por#</p>
</if>
<else>
  <p>#acs-subsite.lt_Sure_erase_user_por#</p>
</else>

<formtemplate id="portrait_erase"></formtemplate>
