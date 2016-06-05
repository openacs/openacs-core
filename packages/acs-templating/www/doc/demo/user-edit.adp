<h2>Edit User Properties</h2>
<hr>

<if @display@ eq "user_edit">
  <formtemplate id="user_edit"></formtemplate>
</if>
<else>

<p>Please search for a user to edit by specifying any portion of a
first or last name.</p>

<table border="0">
  <formtemplate id="user_search">
    <tr>
      <td nowrap><formwidget id="user_search">
      <formerror id="user_search"><br>
        <font color=red>@formerror.user_search;noquote@</font>
      </formerror></td>
      <td nowrap><formwidget id="submit"></td>
    </tr>
  </formtemplate>
</table>
</else>

<if @display@ eq "user_list">
  <p>The following users match your search criteria.  Choose one to
     edit their properties:</p>
   
  <multiple name=users>
    <a href="user-edit?user_id=@users.user_id@">@users.first_name@ 
      @users.last_name@</a><br>
  </multiple>
</if>

