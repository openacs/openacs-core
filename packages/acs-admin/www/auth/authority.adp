<master>
  <property name="context">@context;noquote@</property>
  <property name="title">@page_title;noquote@</property>
  <property name="focus">authority.pretty_name</property>

<if @configure_url@ not nil>
  <p>
    <b>&raquo;</b> <a href="@configure_url@">Configure drivers for this authority</a>
  </p>
</if>

<formtemplate id="authority"></formtemplate>

<if @configure_url@ not nil>
  <p>
    <b>&raquo;</b> <a href="@configure_url@">Configure drivers for this authority</a>
  </p>
</if>

<p>
  <b>&raquo;</b> <a href="@show_users_url@">Show users in this authority</a> (@num_users@ users)
</p>

<if @display_batch_history_p@ true>
  <h2>Batch Jobs</h2>

  <if @batch_sync_run_url@ not nil>
    <p>
      <b>&raquo;</b> <a href="@batch_sync_run_url@" onclick="return confirm('Are you sure you want to run a batch job to sync the user database now?');">Run new batch job now</a>
    </p>
  </if>

  <p><listtemplate name="batch_jobs"></listtemplate></p>
</if>
