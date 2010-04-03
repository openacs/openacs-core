<master>
  <property name="title">@page_title@</property>

<div style="float: right;">
  <a href="developer" class="button">Developer's Admin</a>
</div>

<h1>Core Administration</h1>

<include src="/packages/acs-admin/lib/site-wide-services">

<if @packages:rowcount@ gt 0>
  <h1>Site-Wide Package Administration</h1>
  <listtemplate name="packages"></listtemplate>
</if>

<if @too_many_subsites_p@ gt 0>
  <h1>Subsite Administration</h1>
  <p>Too many subsites to display: @subsite_number@</p>
</if>
<else>

<if @subsites:rowcount@ gt 0>
  <h1>Subsite Administration</h1>
  <ul>
    <multiple name="subsites">
      <li><a href="@subsites.admin_url@">@subsites.path_pretty@</a></li>
    </multiple>
  </ul>
</if>
</else>

<h1>Service Administration</h1>
<include src="/packages/acs-admin/lib/service-parameters">
