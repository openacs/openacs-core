<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>

<if @servers:rowcount@ gt 0>
  <table border="1" cellspacing="0" cellpadding="2">
    <tr>
      <th>Server</th>
      <th>Description</th>
      <th>Last built</th>
      <th>Errors</th>
    </tr>
    <multiple name="servers">
      <tr>
        <if @servers.parse_errors@ not nil>
          <td colspan="4">Could not parse XML file at @servers.path@: @servers.parse_errors@</td>
        </if>
        <else>
          <td><a href="@servers.remote_url@">@servers.name@</a></td>
          <td>@servers.description@</td>
          <td style="white-space:nowrap"><a href="@servers.local_url@">@servers.install_date@</a></td>
	  <if @servers.error_total_count@ eq 0>
            <td style="background-color:green">@servers.error_total_count@</td>
	  </if>
	  <else>
	    <if @servers.error_total_count@ eq "n/a">
              <td style="background-color:yellow">@servers.error_total_count@</td>
            </if>
	    <else>
            <td style="background-color:red"><b>@servers.error_total_count@</b></td>
            </else>
          </else>
        </else>
      </tr>
    </multiple>
  </table>
</if>

<p>Errors cannot be automatically reported for versions of OpenACS prior to 5.1d2.

<if @xml_report_dir@ nil>
  The XMLReportDir parameter is empty so a server listing cannot be generated.
</if>
