<master>
  <property name="context">@context;literal@</property>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="focus">authority.pretty_name</property>

<if @configure_url@ not nil>
  <p>
    <strong>&raquo;</strong> <a href="@configure_url@">Configure drivers for this authority</a>
  </p>
</if>

<formtemplate id="authority"></formtemplate>

<if @configure_url@ not nil>
  <p>
    <strong>&raquo;</strong> <a href="@configure_url@">Configure drivers for this authority</a>
  </p>
</if>

<p>
  <strong>&raquo;</strong> <a href="@show_users_url@">Show users in this authority</a> (@num_users@ users)
</p>

<if @display_batch_history_p;literal@ true>
  <h2>Batch Jobs</h2>

  <if @batch_sync_run_url@ not nil>
    <p>
      <strong>&raquo;</strong> <a href="@batch_sync_run_url@" id="batch-sync-run" class="button">Run new batch job now</a>
    </p>
  </if>

  <p><listtemplate name="batch_jobs"></listtemplate></p>
</if>
