<master>
<property name="context">@context;noquote@</property>
<property name="title">@page_title;noquote@</property>

<blockquote>
  <formtemplate id="authority_form"></formtemplate>
</blockquote>

<if @display_batch_history_p@>
  <h2>Batch Jobs</h2>

  <blockquote>
    <listtemplate name="batch_jobs"></listtemplate>
  </blockquote>
</if>
