<master>
  <property name="title">@page_title@</property>

<div style="float: right;">
  <a href="developer" class="button">Developer's Admin</a>
</div>

<h3>Core Administration</h3>

<include src="/packages/acs-admin/lib/site-wide-services">

<if @packages:rowcount@ gt 0>
  <h3>Site-Wide Package Administration</h3>
  <ul>
    <multiple name="packages">
      <li><a href="@packages.admin_url@/\">@packages.pretty_name@</a></li>
    </multiple>
  </ul>
</if>

<if @subsites:rowcount@ gt 0>
  <h3>Subsite Administration</h3>
  <ul>
    <multiple name="subsites">
      <li><a href="@subsites.admin_url@">@subsites.path_pretty@</a></li>
    </multiple>
  </ul>
</if>

<h3>Service Administration</h3>

<include src="/packages/acs-admin/lib/service-parameters">

