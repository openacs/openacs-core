<master>
  <property name="context">@context;noquote@</property>
  <property name="title">@page_title;noquote@</property>
  <property name="focus">authority.pretty_name</property>

<formtemplate id="authority"></formtemplate>

<if @display_batch_history_p@ true>
  <h2>Batch Jobs</h2>

  <if @batch_sync_run_url@ not nil>
    <p>
      <b>&raquo;</b> <a href="@batch_sync_run_url@" onclick="return confirm('Are you sure you want to run a batch job to sync the user database now?');">Run new batch job now</a>
    </p>
  </if>

  <listtemplate name="batch_jobs"></listtemplate>
</if>
