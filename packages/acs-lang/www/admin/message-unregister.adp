<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<p>
  Permanently deleting (unregistering) message key <strong>@package_key@.@message_key@</strong> in all locales.
</p>

<form action="message-unregister">
    @form_export_vars;noquote@
    <input type="submit" value="Confirm unregister">
</form>
