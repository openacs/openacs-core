<ul>
  <li><a href="@acs_admin_url@apm">Package Manager</a>
  <li><a href="@acs_admin_url@cache">Cache Info</a>
  <if @acs_automated_testing_url@ not nil>
    <li><a href="@acs_automated_testing_url@admin">Automated Testing</a>
  </if>
  <if @acs_service_contract_url@ not nil>
    <li><a href="@acs_service_contract_url@">Service Contracts</a>
  </if>
  <li><a href="@acs_api_browser_url@">API Browser</a>
  <li><a href="@acs_core_docs_url@">Documentation</a>
  <if @acs_developer_support_url@ not nil>
    <li><a href="@acs_developer_support_url@">Developer Support</a>
  </if>
</ul>
<p>
