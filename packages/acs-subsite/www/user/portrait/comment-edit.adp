<master>
<property name="title">Edit comment for the portrait of @first_names@ @last_name@</property>
<property name="context">@context@</property>

<form method="post" action="comment-edit-2.tcl">
@export_vars@
Story Behind Photo:<br />
<textarea rows="6" cols="50" wrap="soft" name="description">
@description@
</textarea>


<p><center>
<input type="submit" value="Save comment" />
</center></p>
</form>


