<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>

<ul>
  <multiple name="servers">
    <li>
      <if @servers.parse_errors@ not nil>Could not parse XML file at @servers.path@: @servers.parse_errors@</if>
      <else>
        <a href="@servers.url@">@servers.name@</a>
        (@servers.install_date@, @servers.error_total_count@ errors)
      </else>
    </li>
  </multiple>
</ul>

<if @xml_report_dir@ nil>
  The XMLReportDir parameter is empty so a server listing cannot be generated.
</if>