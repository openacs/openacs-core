<h3>Package specification Summary for package @package_key@ </h3>

<table>
<tr>
  <th>Description </th>
  <td>@info.description@ </td>
</tr>
<tr>
  <th>Maturity </th>
  <td>@maturity@ </td>
</tr>
<tr>
  <th>This package depends on: </th>
  <td><if @deps:rowcount@ eq 0>None</if><else><multiple name="deps">@deps.name@ </multiple></else></td>
</tr>
<tr>
  <th>Packages that depend on @package_key@ </th>
  <td><if @dependees:rowcount@ eq 0>None</if><else><multiple name="dependees">@dependees.name@ </multiple></else> </td>
</tr>
</table>
