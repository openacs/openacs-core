<master>
 <property name="doc(title)">Edit a message</property>
 <property name="context">@context;literal@</property>
 <property name="focus">message.message</property>

<!-- TODO: Remove 'style' when we've merged 4.6.4 back onto HEAD -->
<formtemplate id="message_form"></formtemplate>

<h2>Audit Trail</h2>

@first_translated_message;noquote@

<include src="audit-include" current_locale="@current_locale;literal@" message_key="@message_key;literal@" package_key="@package_key;literal@">

<h2>Files that use this message</h2>
<if @usage_p;literal@ true>
  <p>
    <strong>Show</strong> | <a href="@usage_hide_url@">Hide</a> files that use this message.
  </p>
  <include src="message-usage-include" message_key="@message_key;literal@" package_key="@package_key;literal@">
</if>
<else>
  <p>
    <a href="@usage_show_url@">Show</a> | <strong>Hide</strong> files that use this message key.
  </p>
</else>

<if @create_p;literal@ true>
  <ul class="action-links">
    <li> <a href="@delete_url@">Delete this message</a></li>
  </ul>
</if>
