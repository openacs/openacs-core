<master>

<strong>Displaying:</strong>
<p>
  <ul>
    <li>Locale: @locale@</li>
    <li>Number of edits: @number_of_edits@</li
    <li>Excluding emails like: @email_exclude@</li>
  </ul>
</p>

<p>
  <formtemplate id="locale"></formtemplate>
</p>

<table>
  <tr>
    <th>Key</th>
    <th>Overwrite date</th>
    <th>Old message</th>
    <th>User</th>
  </tr>

  <multiple name="history">
    <tr>
      <td><a href="@history.key_url@">@history.package_key@.@history.message_key@</a></td>  
      <td>@history.overwrite_date@</td>  
      <td>@history.old_message@</td>  
      <td>@history.user_name@
    </tr>
  </multiple>
</table>
