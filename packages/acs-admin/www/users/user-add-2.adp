<master>
<property name=title>Add a user</property>

<h2>Add a user</h2>

@context_bar@

<hr>

@first_names@ @last_name@ has been added to @system_name@.
Edit the message below and hit "Send Email" to 
notify this user.

<p>
<form method=POST action="user-add-3">
@export_vars@
Message:

<p>

<textarea name=message rows=10 cols=70 wrap=hard>
@first_names@ @last_name@, 

You have been added as a user to @system_name@
at @system_url@

Login information:
Email: @email@
Password: @password@
(you may change your password after you log in)

Thank you,
@administration_name@
</textarea>

<p>

<center>

<input type=submit value="Send Email">

</center>

</form>
<p>


