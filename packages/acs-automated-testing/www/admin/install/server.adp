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
  <li>Login:
    <ul>
      <li><a href="@admin_login_url@">Admin user</a>
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
  <li>Logs
    <ul>
      <li><a href="@service.auto_test_url@">Automated testing</a>
      <li>Install Log (TODO)
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
