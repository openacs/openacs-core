<master>
<property name="doc(title)">Registration History</property>
<property name="context">@context;literal@</property>
<table>
  <tr><th>Year</th><th align="left">Month</th><th>Registrations</th></tr>
<multiple name="user_rows">
  <tr><td>@user_rows.pretty_year@</td>
      <td>@user_rows.pretty_month@</td>
      <td align="right">@user_rows.n_new@</td>
  </tr>
</multiple>
</table>


