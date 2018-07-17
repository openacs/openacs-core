<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>


<listfilters name="packages" style="inline-filters"></listfilters>
<if @packages:rowcount;literal@ eq 0>
  <if @upgrade_p;literal@ true>
    <p> No packages on your system need upgrading. </p>
  </if>
  <else>
    <if @repository_url@ nil>
      <p> There are no un-installed applications in your file system meeting the filter criteria.</p>
    </if>
    <else>
      <p> There are no un-installed applications in the OpenACS repository meeting the filter criteria. </p>
    </else>
  </else>
</if>
<else>
  <listtemplate name="packages"></listtemplate>
</else>

<p> <strong>&raquo;</strong> <a href=".">Go back to software installation</a>
