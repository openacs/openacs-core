<ul>
  <li><a href="@acs_admin_url@users">Users</a>
  <li><a href="subsites">Subsites</a> (@nr_subsites@)</li>
  <li>OpenACS Packages
    <ul>
    <li><a href="@acs_admin_url@apm">Package Manager</a>
    <li><a href="@acs_admin_url@install/">Install or Upgrade Packages</a>
    <li><a href="@acs_lang_admin_url@">Internationalization/Localization</a>
    </ul>
  <li><a href="developer">Developer Tools</a>
  <if @acs_lang_admin_url@ not nil>
  </if>
  <li><a href="@acs_admin_url@auth">Authentication</a>
  <li><a href="/admin/host-node-map/">#acs-subsite.Host_Node_Map#</a></li>
  <li><a href="@acs_admin_url@monitor">Active connections</a><if @request_monitor_url@ defined>, <a href="@request_monitor_url@">XOTcl Request Monitor</a></if>
  <li><a href="@acs_admin_url@server-restart">Server Restart</a>  
  <li><a href="@acs_core_docs_url@">Documentation</a>
</ul>
