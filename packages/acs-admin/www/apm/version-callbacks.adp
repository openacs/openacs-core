<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>


<if @callbacks:rowcount@ gt 0>
<table>
<tr>
  <th>Type</th>
  <th>Tcl Proc</th>
  <th>Action</th>
</tr>

<multiple name="callbacks">
  <tr>
     <td>@callbacks.type@</td>
     <td>@callbacks.proc@</td>
     <td><a href="version-callback-add-edit?version_id=@version_id@&type=@callbacks.type@">Edit</a> 
         <a href="version-callback-delete?version_id=@version_id@&type=@callbacks.type@">Delete</a></td>
  </tr>
</multiple>
</ul>

</table>
</if>
<else>
<i>There are no Tcl callbacks defined for the package.</i>
</else>

<if @unused_types_p@ eq 1>
<p>
<a href="version-callback-add-edit?version_id=@version_id@">Add callback</a>
</p>
</if>
