<master>
<property name="context">@context;noquote@</property>
<property name="title">@subsite_name;noquote@ Administration</property>

<h3>Subsite Administration</h3>
<ul>
  <li>@subsite_name@
    <ul>
      <li><a href=site-map/>Site Map</a>
      <li><a href=groups/>Groups</a>
      <li><a href=group-types/>Group Types</a>
      <li><a href=rel-segments/>Relational Segments</a>
      <li><a href=rel-types/>Relationship Types</a>
      <li><a href=host-node-map/>Host-Node Map</a>
      <li><a href=object-types/>Object Types</a>
    </ul>
  </li> 
</ul>

<h3>Core Services</h3>
<ul>
  <li>
    <a href="@acs_admin_url@">@acs_admin_name@</a>
    <include src="/packages/acs-admin/lib/site-wide-services">
  </li>
</ul>
