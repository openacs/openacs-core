<master>
  <property name="context">@context;noquote@</property>
  <property name="title">@page_title;noquote@</property>
  <property name="focus">authority.pretty_name</property>

<formtemplate id="authority"></formtemplate>

<if @display_batch_history_p@ true>
  <h2>Batch Jobs</h2>

  <listtemplate name="batch_jobs"></listtemplate>
</if>
