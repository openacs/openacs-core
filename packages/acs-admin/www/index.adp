<master>
  <property name="title">@page_title@</property>

<h3>Core Services</h3>

<ul>
  <li><a href=apm>ACS Package Manager</a>
  <li><a href=users>Users</a>
  <li><a href=cache>Cache info</a>
</ul>
<p>

<if @subsites:rowcount@ gt 0>
  <h3>Subsite Administration</h3>
  <ul>
    <multiple name="subsites">
      <li><a href="@subsites.admin_url@">@subsites.instance_name@ Administration</a></li>
    </multiple>
  </ul>
</if>

<if @packages:rowcount@ gt 0>
  <h3>Package Administration</h3>
  <ul>
    <multiple name="packages">
      <li><a href="@packages.admin_url@/\">@packages.pretty_name@</a></li>
    </multiple>
  </ul>
</if>
