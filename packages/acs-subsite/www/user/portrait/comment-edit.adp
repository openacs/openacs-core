<master>
<property name=title>Edit comment for the portrait of @first_names@ @last_name@</property>

<h2>Edit comment for the portrait of @first_names@ @last_name@</h2>

@context_bar@

<hr>

<blockquote>
<form method=post action=comment-edit-2.tcl>
@export_vars@
Story Behing Photo:<br>
<textarea rows=6 cols=50 wrap=soft name=description>
@description@
</textarea>

<p>

<center>
<input type=submit value="Save comment">
</center>
</blockquote>
</form>


