<master>
<property name="title">#notifications.Manage_Notifications#</property>
<property name="context">#notifications.Manage_Notifications#</property>

<table class="table-display" cellpadding="5" cellspacing="1" bgcolor="#999999">
    <tr class="table-header" bgcolor="white">
      <th>#notifications.Notification_type#</th>
      <th>#notifications.Item#</th>
      <th>#notifications.Frequency#</th>
      <th>#notifications.Action#</th>
    </tr>
<multiple name="notifications">

  <if @notifications.rownum@ odd>
    <tr class="odd" bgcolor="white">
  </if>
  <else>
    <tr class="even" bgcolor="#e9e9e9">
  </else>
    <td>@notifications.type@</td>
    <td><a href=object-goto.tcl?object_id=@notifications.object_id@&type_id=@notifications.type_id@>@notifications.object_name@</a></td> 
    <td>@notifications.interval@ (<a href=request-change-frequency.tcl?return_url=@return_url@&request_id=@notifications.request_id@>#notifications.Change#</a>)</td> 
    <td><a href=request-delete.tcl?return_url=@return_url@&request_id=@notifications.request_id@>#notifications.Unsubscribe#</a></td>
  </tr>
</multiple>

<if @notifications:rowcount@ eq 0>
  <tr>
    <td colspan=4 bgcolor="white"><i>#notifications.lt_You_have_no_notificat#</i></td>
  </tr>
</if>

</table>


