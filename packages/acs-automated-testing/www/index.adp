<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>

<if @servers:rowcount@ gt 0>
  <table border="1">
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
          <td><a href="@servers.url@">@servers.name@</a></td>
          <td>@servers.description@</td>
          <td>@servers.install_date@</td>
          <td>@servers.error_total_count@ errors</td>
        </else>
      </tr>
    </multiple>
  </table>
</if>

<if @xml_report_dir@ nil>
  The XMLReportDir parameter is empty so a server listing cannot be generated.
</if>
