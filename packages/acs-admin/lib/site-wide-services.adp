<ul>
  <li><a href="@acs_admin_url@users">Users</a> 
  <li><a href="@acs_admin_url@apm">Package Manager</a>
  <li><a href="@acs_admin_url@cache">Cache Info</a>
  <if @acs_automated_testing_url@ not nil>
    <li><a href="@acs_automated_testing_url@admin">Automated Testing</a>
  </if>
  <if @acs_lang_admin_url@ not nil>
    <li><a href="@acs_lang_admin_url@">Internationalization/Localization</a>
  </if>
  <if @acs_service_contract_url@ not nil>
    <li><a href="@acs_service_contract_url@">Service Contracts</a>
  </if>
</ul>
<p>
