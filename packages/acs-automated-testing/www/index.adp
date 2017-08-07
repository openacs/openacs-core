<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<if @servers:rowcount@ gt 0>
  <table border="1" cellspacing="0" cellpadding="3">
    <tr>
      <th>Server</th>
      <th>Login</th>
      <th>Description</th>
      <th>Last built</th>
      <th>Errors</th>
      <th>Details</th>
    </tr>
    <tr>
      <td><strong>This server</strong></td>
      <td colspan="4" align="center"><a href="admin/">Automated Test Admin</a></td>
    </tr>
    <multiple name="servers">
      <tr>
        <if @servers.parse_errors@ not nil>
          <td colspan="4">Could not parse XML file at @servers.path@: @servers.parse_errors@</td>
        </if>
        <else>
          <td><a href="@servers.remote_url@">@servers.name@</a></td>
	  <td><a href="@servers.admin_login_url@">Admin</a></td>
          <td>@servers.description;noquote@</td>
          <td style="white-space:nowrap">@servers.install_date@</td>
	  <if @servers.error_total_count@ eq 0>
            <td style="background-color:green">@servers.error_total_count@</td>
	  </if>
	  <else>
	    <if @servers.error_total_count@ eq "n/a">
              <td style="background-color:yellow">@servers.error_total_count@</td>
            </if>
	    <else>
            <td style="background-color:red"><strong>@servers.error_total_count@</strong></td>
            </else>
          </else>
          <td style="white-space:nowrap"><a href="@servers.local_url@">More info</a></td>
        </else>
      </tr>
    </multiple>
  </table>
</if>

<p>Error reporting is not available for versions of OpenACS prior to 5.1d2.
<p><a href="doc/">Documentation</a>
<if @xml_report_dir@ nil>
  The XMLReportDir parameter is empty so a server listing cannot be generated.
</if>

