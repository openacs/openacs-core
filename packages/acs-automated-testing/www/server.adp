<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>

<ul>
  <li>Service:
    <ul>
      <li>Name: @service.name@</li>
      <li>Description: @service.description@</li>
      <li>URL: <a href="@service.url@">@service.url@</a>
    </ul>
  </li>
  <li>Login as:
    <ul>
      <li><a href="@admin_login_url@">Admin user</a> (pwd: @service.adminpassword@)
    </ul>
  </li>
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
  <li>Test failures
    <if @has_test_report_p@>
      <if @testcase_failures:rowcount@ eq 0>
        <i>none</i>
      </if>
      <else>
        <table>
          <tr>
            <th>Test case</th>
            <th>Failure count</th>
          </tr>
        <multiple name="testcase_failures">
          <tr>
            <td>@testcase_failures.testcase_id@</td>
            <td align="center">@testcase_failures.count@</td>
          </tr>
        </multiple>      
        </table>
      </else>
    </if>
    <else>
      <p>
        Unknown. Missing test report file at path @test_path@
      </p>
    </else>
  </li>
  <li>
    <a href="@rebuild_url@" onclick="return confirm('Are you sure you want to wipe and rebuild this server?');">Rebuild this server now</a>
  </li>
  <li>
    <a href="@rebuild_log_url@">Rebuild log</a>
  </li>
</ul>

