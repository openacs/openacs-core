<master>
<property name="doc(title)">Add a user</property>
<property name="context">@context;literal@</property>


<p>
@first_names@ @last_name@ has been added to @system_name@.
Edit the message below and hit "Send Email" to 
notify this user.
</p>

<p>
<form method="post" action="user-add-3">
<input type="hidden" name="referer" value="@referer@"></input>
@export_vars;noquote@
Message:
<textarea name=message rows=10 cols=70 wrap=hard>
@first_names@ @last_name@, 

You have been added as a user to @system_name@
at @system_url@.

Login information:
Email: @email@
Password: @password@
(you may change your password after you log in)

Thank you,
@administration_name@
</textarea>

<center>
<input type="submit" value="Send Email">
</center>

</form>
</p>
