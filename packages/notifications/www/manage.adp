<master>
<property name="title">#notifications.Manage_Notifications#</property>
<property name="context">#notifications.manage_notifications#</property>

<table  width="85%" class="table-display" cellpadding="5" cellspacing="0">
    <tr class="table-header">
      <td>#notifications.Notification_type#</td>
      <td>#notifications.Item#</td>
      <td>#notifications.Frequency#</td>
      <td>#notifications.Action#</td>
    </tr>
<multiple name="notifications">
<if @notifications.rownum@ odd>
    <tr class="odd">
</if>
<else>
    <tr class="even">
</else>
  <td>@notifications.type@</td>
  <td><a href=object-goto.tcl?object_id=@notifications.object_id@>@notifications.object_name@</a></td> 
  <td>@notifications.interval@</td> 
  <td><a href=request-delete.tcl?return_url=@return_url@&request_id=@notifications.request_id@>#notifications.Unsubscribe#</a></td>
</tr>
</multiple>

<if @notifications:rowcount@ eq 0>
  <tr>
    <td colspan=4><i>#notifications.lt_You_have_no_notificat#</i></td>
  </tr>
</if>

</table>


