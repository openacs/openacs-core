<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>

<ul>
  <li>Service:
    <ul>
      <li>URL: <a href="@service.url@">@service.url@</a>
    </ul>
  </li>
  <li>Installation: 
    <ul>
      <li>Installation completed at: @service.install_end_timestamp@
      <li>Duration: @service.install_duration_pretty@
    </ul>
  </li>
  <li>Sources
    <ul>
      <li>OS: @service.os@
      <li>DB: @service.dbtype@ @service.dbversion@
      <li>Webserver: : @service.webserver@
      <li>Openacs flag: @service.openacs_cvs_flag@
    </ul>
  </li>
  <li>Users
    <ul>
      <li>Admin: <a href="@service.admin_login_url@">@service.adminemail@/@service.adminpassword@</a>
    </ul>
  </li>
  <li>Logs
    <ul>
      <li><a href="@service.auto_test_url@">Automated testing</a>
      <li>Install Log (TODO)
      <li>
    </ul>
  </li>
</ul>

<h3>Rebuild</h3>

<ul
  <li>
    To rebuild this server:
    <ol>
      <li>
        SSH to @service.hostname@
      </li>
      <li>
        Execute @service.rebuild_cmd@
      </li>
    </ol>
  </li>
</ul>

<h3>Tar-ball</h3>

<p>
  TODO
</p>
