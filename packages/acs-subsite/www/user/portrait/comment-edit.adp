<master src="master">
<property name="title">Edit comment for the portrait of @first_names@ @last_name@</property>
<property name="context_bar">@context_bar@</property>

<form method="post" action="comment-edit-2.tcl">
@export_vars@
Story Behing Photo:<br />
<textarea rows="6" cols="50" wrap="soft" name="description">
@description@
</textarea>


<p><center>
<input type="submit" value="Save comment" />
</center></p>
</form>


