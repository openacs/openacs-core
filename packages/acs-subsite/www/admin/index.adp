<master>

<h2>@subsite_name@ Administration</h2>
<ul>
  <li><a href="applications/">Applications</a>
  <li><a href="configure">Configure</a>
  <li><a href="permissions">Permissions</a>
  <li><a href="../members/">Members</a>
  <li><a href="../shared/parameters">Parameters</a>
  <li><a href="subsite-add">Create new subsite</a>
</ul>

<h2>Advanced Features</h2>

<ul>
  <li><a href=site-map/>Site Map</a>
  <li><a href=groups/>Groups</a>
  <li><a href=group-types/>Group Types</a>
  <li><a href=rel-segments/>Relational Segments</a>
  <li><a href=rel-types/>Relationship Types</a>
  <li><a href=host-node-map/>Host-Node Map</a>
  <li><a href=object-types/>Object Types</a>
  <if @asm_p@ eq 1>
  <li><a href=set-reg-assessment> #acs-subsite.reg_asm_link#</a>
  </if>
</ul>

<if @sw_admin_p@ true>
  <h3>Core Services</h3>
  <ul>
    <li>
      <a href="@acs_admin_url@">@acs_admin_name@</a>
      <include src="/packages/acs-admin/lib/site-wide-services">
    </li>
  </ul>
</if>
