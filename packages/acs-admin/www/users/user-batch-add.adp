<master>
<property name=title>Add a batch of users</property>
<property name="context">@context;noquote@</property>

<form method="post" action="user-batch-add-2">
<p>Add these users to @system_name@, one user per line.</p>
<br /><textarea name=userlist rows=15 cols=50>
email, first name, last name
</textarea>
<p>Each user will get this email:
<br />From: <input name="from" value="@admin_email@">
<br />Subject: <input name=subject value="You have been added as a user to @system_name@ at @system_url@" size=50>
<p>Message: (The four variables delimited by {) marks will be automatically set for each user.)
<br /><textarea name="message" rows=10 cols=70 wrap=hard>
{first_names} {last_name}

You have been added as a user to @system_name@
at @system_url@

Login information:
Email: {email}
Password: {password} 
(you may change your password after you log in)

Thank you,
@administration_name@
</textarea>
</p>
<center>
<input type="submit" value="Import List and Send Emails" />
</center>

</form>
</p>


