<master>
<property name=title>Registration History</property>

<h2>Registration History</h2>

@context_bar@

<hr>

<blockquote>
<table>
  <tr><td><b>Year</b></td>
      <td><b>Month</b></td>
      <td><b>Registrations</b></td>
  </tr>

<multiple name="user_rows">

  <tr><td>@user_rows.pretty_year@</td>
      <td>@user_rows.pretty_month@</td>
      <td>@user_rows.n_new@</td>
  </tr>

</multiple>

</table>
</blockquote>

