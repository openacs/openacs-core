<master src="master">
<property name="title">Administration of Localized Messages</property>

<h2>Delete locale</h2>
@context_bar@
<hr />

<p style="color: red; font-weight: bold">Are you sure you want to proceed?</p>
<p />
<form action="locale-delete" method="post">
@confirm_data@
<input type="submit" value="Delete..." />
</form>
