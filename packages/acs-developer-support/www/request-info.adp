<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

@body;noquote@

<if @dbreqs:rowcount@ gt 0>
  <listfilters name="dbreqs" style="inline-filters"></listfilters>
  <listtemplate name="dbreqs"></listtemplate>
</if>
