<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>


<listfilters name="packages" style="inline-filters"></listfilters>
<if @packages:rowcount@ eq 0>
  <if @upgrade_p@ true>
    <p> No packages on your system need upgrading. </p>
  </if>
  <else>
    <if @repository_url@ nil>
      <p> There are no un-installed applications in your file system. </p>
    </if>
    <else>
      <p> There are no un-installed applications in the OpenACS repository. </p>
    </else>
  </else>
</if>
<else>
  <listtemplate name="packages"></listtemplate>
</else>

<p> <b>&raquo;</b> <a href=".">Go back to software installation</a>
