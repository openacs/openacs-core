<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<if @packages:rowcount@ eq 0>
  <if @upgrade_p@ true>
    <p> No packages on your system needs upgrading. </p>
  </if>
  <else>
    <p> There are no un-installed applications in your file system. </p>
  </else>
  <p> <b>&raquo;</b> <a href="/acs-admin/">Go back to site-wide administration</a>
</if>
<else>
  <p><listtemplate name="packages"></listtemplate></p>
</else>
