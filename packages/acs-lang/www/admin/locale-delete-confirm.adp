<master src="master">
<property name="title">Delete locale confirmation</property>
<property name="context_bar">@context_bar@</property>

<p style="color: red; font-weight: bold">Are you sure you want to proceed?</p>
<p />
<form action="locale-delete" method="post">
@confirm_data@
<input type="submit" value="Delete..." />
</form>
