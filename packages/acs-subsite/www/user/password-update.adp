<master>
<property name=title>Update Password</property>

<h2>Update Password</h2>

for @first_names@ @last_name@ in @site_link@

<hr>

<form method=POST action="password-update-2">
@export_vars@
<table>

<if @admin_enabled_p@ eq 0>
<tr>
    <th>Current Password:<td><input type=password name=password_old size=15>
</tr>
</if>

<tr>
 <th>New Password:<td><input type=password name=password_1 size=15>
</tr>
<tr>
 <th>Confirm:<td><input type=password name=password_2 size=15>
</tr>
</table>

<br>
<br>
<center>
<input type=submit value="Update">
</center>

