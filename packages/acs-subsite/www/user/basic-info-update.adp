<master>
<property name=title>Update Basic Information</property>

<h2>Update Basic Information</h2>

in @site_link@

<hr>

<form method=POST action="basic-info-update-2">
@export_vars@
<table>
<tr>
<tr>
 <th>Name:<td><input type=text name=first_names size=20 value="@first_names@"> <input type=text name=last_name size=25 value="@last_name@">
</tr>
<tr>
 <th>email address:<td><input type=text name=email size=30 value="@email@">
</tr>
<tr>
 <th>Personal URL:<td><input type=text name=url size=50 value="@url@"></tr>
</tr>
<tr>
 <th>screen name:<td><input type=text name=screen_name size=30 value="@screen_name@">
</tr>
<tr>
 <th>Biography:<td><textarea name=bio rows=10 cols=50 wrap=soft>@bio@</textarea></td>
</tr>
</table>

<br>
<br>
<center>
<input type=submit value="Update">
</center>


