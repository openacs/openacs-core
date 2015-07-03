<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<p />

<p>
  Deleting message for key <strong>@package_key@.@message_key@</strong> in locale @locale@.
</p>

<form action="message-delete">
@form_export_vars;noquote@
<input type="submit" value="Confirm delete">
</form>
