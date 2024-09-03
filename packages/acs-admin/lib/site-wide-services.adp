<ul>
  <li><a href="@acs_admin_url@posture-overview">Security and Privacy Posture Overview</a>
  <li><a href="@acs_admin_url@users">Users</a>
  <li><a href="@acs_admin_url@auth">Authentication</a>
  <li><a href="subsites">Subsites</a> (@nr_subsites@)</li>
  <li><a href="/admin/host-node-map/">#acs-subsite.Host_Node_Map#</a></li>
  <li><a href="@acs_lang_admin_url@">Internationalization/Localization</a>
  <if @cluster_enabled_p@ true><li><a href="cluster">Cluster Nodes</li></if>
  <li><a href="@acs_admin_url@server-restart">Server Restart</a>
  <li><a href="@acs_core_docs_url@">Documentation</a>
</ul>
<ul class="col-xl-8 col-lg-10 col-12 list-group list-group-horizontal">
  <li class="list-group-item flex-fill"><strong>OpenACS Packages</strong>
    <ul>
    <li><a href="@acs_admin_url@apm">Package Manager</a>
    <li><a href="@acs_admin_url@install/">Install or Upgrade Packages</a>
    </ul>
  <li class="list-group-item flex-fill"><strong>Developer Tools</strong>
  <ul>
     <if @acs_api_browser_url@ not nil><li><a href="@acs_api_browser_url@">API Browser</a></li></if>
       <if @acs_developer_support_url@ not nil><li><a href="@acs_developer_support_url@">Developer Support</a></li></if>
     <li><a href="developer">More ...</a></li>
  </ul>
  </li>
  <li class="list-group-item flex-fill"><strong>Monitoring</strong>
  <ul>
  <if @nsstats_url@ not nil><li><a href="@nsstats_url@">NaviServer Statistics</a></li></if>
  <if @request_monitor_url@ not nil><li><a href="@request_monitor_url@">XOTcl Request Monitor</a></li></if>
  <li><a href="@acs_admin_url@monitor">Active connections</a>
  </ul>
</ul>
<p>