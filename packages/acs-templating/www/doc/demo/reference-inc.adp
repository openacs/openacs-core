<h2>Passed-in Users</h2>
This included template uses a @users:rowcount@-row datasource passed
by reference.

<ul>
<multiple name=users>
  <li>@users.first_name@ @users.last_name@ (from @users.state@)
</multiple>
</ul>
