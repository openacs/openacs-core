<master>
  <property name="title">@page_title@</property>
  <property name="context">@context;noquote@</property>

<p />
<br />
<p>
  Deleting message for key <strong>@package_key@.@message_key@</strong> in locale <strong>@locale@</strong>.
</p>
<br />

<p>
  <if @unregister_p@>
     If you confirm with <strong>"Confirm unregister"</strong>, then the message <strong>@package_key@.@message_key@</strong> 
     is completely removed from all locales.
  </if>
</p>

<p />
<br />

<form action="message-delete">
  @form_export_vars;noquote@
  <input type="submit" name="subm_delete" value="Confirm 'delete in locale'">
  <if @unregister_p@>
    <input type="submit" name="subm_unreg" value="Confirm 'unregister'">
  </if>
</form>
