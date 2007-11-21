<master>
<property name="title">#acs-subsite.lt_Edit_comment_for_the_#</property>
<property name="context">@context;noquote@</property>

<div>
<form method="post" action="comment-edit-2.tcl">
<div>@export_vars;noquote@</div>
<p>#acs-subsite.Story_behind_photo#:</p>
<p>
<textarea rows="6" cols="50" name="description">
@description@
</textarea>
</p>

<p style="text-align:center">
<input type="submit" value="#acs-subsite.Save_comment#">
</p>
</form>
</div>
