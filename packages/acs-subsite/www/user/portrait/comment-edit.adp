<master>
<property name="title">#acs-subsite.lt_Edit_comment_for_the_#</property>
<property name="context">@context;noquote@</property>

<form method="post" action="comment-edit-2.tcl">
@export_vars;noquote@
#acs-subsite.Story_behind_photo#:<br />
<textarea rows="6" cols="50" wrap="soft" name="description">
@description@
</textarea>


<p><center>
<input type="submit" value="#acs-subsite.Save_comment#" />
</center></p>
</form>



