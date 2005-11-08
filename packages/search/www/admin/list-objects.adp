<master>
<property name=title>Search Admin Page</property>
<property name="context">@context;noquote@</property>
<table>
  <tr><th>Object Type</th><th align="left">Objects in the Index</th></tr>
<multiple name="objects_per_type">
  <tr><td><a href="list-object?object_id=@objects_per_type.object_id@">@objects_per_type.object_id@</a></td>
      <td>@objects_per_type.object_name@</td>
  </tr>
</multiple>
</table>                                                                                                                    