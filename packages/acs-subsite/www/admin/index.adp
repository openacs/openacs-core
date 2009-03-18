<master>
<property name="doc(title)">@title;noquote@</property>

<h1>@title;noquote@</h1>
<ul>
  <li><a href="applications/">Applications</a>
  <li><a href="configure">Configure</a>
  <li><a href="permissions">Permissions</a>
  <li><a href="../members/">Members</a>
  <li><a href="../shared/parameters">Parameters</a>
  <li><a href="subsite-add">Create new subsite</a>
  <if @convert_subsite_p@>
    <li><a href="subsite-convert-type">Convert to descendent subsite type</a>
  </if>
</ul>

<h1>Advanced Features</h1>

<ul>
  <li><a href="site-map/">Site Map</a>
  <li><a href="groups/">Groups</a>
  <li><a href="group-types/">Group Types</a>
  <li><a href="rel-segments/">Relational Segments</a>
  <li><a href="rel-types/">Relationship Types</a>
  <li><a href="host-node-map/">Host-Node Map</a>
  <li><a href="object-types/">Object Types</a>
</ul>

<if @sw_admin_p@ true>
  <h1>Core Services</h1>
  <ul>
    <li>
      <a href="@acs_admin_url@">@acs_admin_name@</a>
      <include src="/packages/acs-admin/lib/site-wide-services">
    </li>
  </ul>
</if>
