<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<p>
  Undeleting message for key <strong>@package_key@.@message_key@</strong> in locale @locale@.
</p>

<form action="message-undelete">
    @form_export_vars;noquote@
    <input type="submit" value="Confirm undelete">
</form>
