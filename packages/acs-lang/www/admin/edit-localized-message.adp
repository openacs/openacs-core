<master>
 <property name="title">Edit a message</property>
 <property name="context">@context;noquote@</property>
 <property name="focus">message.message</property>

<!-- TODO: Remove 'style' when we've merged 4.6.4 back onto HEAD -->
<formtemplate id="message"></formtemplate>

<h2>Audit Trail</h2>

@first_translated_message;noquote@

<include src="audit-include" current_locale="@current_locale;noquote@" message_key="@message_key;noquote@" package_key="@package_key;noquote@">

<h2>Files that use this message</h2>
<if @usage_p@ true>
  <p>
    <b>Show</b> | <a href="@usage_hide_url@">Hide</a> files that use this message.
  </p>
  <include src="message-usage-include" message_key="@message_key;noquote@" package_key="@package_key;noquote@">
</if>
<else>
  <p>
    <a href="@usage_show_url@">Show</a> | <b>Hide</b> files that use this message key.
  </p>
</else>

<if @create_p@ true>
  <ul class="action-links">
    <li> <a href="@delete_url@">Delete this message</a></li>
  </ul>
</if>
