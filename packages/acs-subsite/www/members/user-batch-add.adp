<master>
<property name=title>Add a batch of users</property>
<property name="context">@context;noquote@</property>

<form method="post" action="user-batch-add-2">
<p>
  Add these users to @system_name@, one user per line. The format of the lines should be:
</p>
<p>
  <code>
  user@example.net, Jane, Austin<br />
  user2@example.net, Emily, Dickinson
  </code>
</p>

<textarea name=userlist rows=15 cols=50></textarea>

<p>Each user will get this email:
<br />From: <input name="from" value="@admin_email@">
<br />Subject: <input name=subject value="You have been added as a user to @system_name@ at @system_url@" size=50>
<p>Message:
<br /><textarea name="message" rows=10 cols=70 wrap=hard>
Dear &lt;first_names&gt; &lt;last_name&gt;,

You have been added as a user to @system_name@
at @system_url@

Login information:
Email: &lt;email&gt;
Password: &lt;password&gt;
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


