<master src="master">
  <property name="title">Localized Messages</property>
  <property name="context_bar">@context_bar@</property>

<div>

<p>You are editing locale: <strong>@locale_label@</strong> [ <tt>@current_locale@</tt> ]</p>

<if @missing_translation:rowcount@ eq 0>

</if>

<else>

<p>Messages that <strong>need</strong> translation in the <b>@package_key@</b> package.</p>

<table cellpadding="0" cellspacing="0" border="0">
 <tr>
  <td style="background: #CCCCCC">
   <table cellpadding="4" cellspacing="1" border="0">
    <tr style="background: #FFFFe4">
     <th>Key</th>
     <th>Original Message</th>
     <th>Translated Message</th>
     <th>Action</th>
    </tr>
    <multiple name="missing_translation">
    <tr style="background: #EEEEEE">
     <td>@missing_translation.message_key@</td>
     <td>@missing_translation.default_message@</td>
     <td>TRANSLATION MISSING</td>
     <td>
      (<span class="edit-anchor"><a href="edit-localized-message?message_key=@missing_translation.escaped_key@&locales=@missing_translation.escaped_language@&package_key=@escaped_package_key@&translated_p=0">edit</a></span>)
     </td>
    </tr>
    </multiple>
   </table>
  </td>
 </tr>
</table>

</else>

<if @translated_messages:rowcount@ eq 0>

</if>

<else>

<p>Messages that <strong>are</strong> translated.</p>

<table cellpadding="0" cellspacing="0" border="0">
 <tr>
  <td style="background: #CCCCCC">
   <table cellpadding="4" cellspacing="1" border="0">
    <tr style="background: #FFFFe4">
     <th>Key</th>
     <th>Original Message</th>
     <th>Translated Message</th>
     <th>Action</th>
    </tr>
    <multiple name="translated_messages">
    <tr style="background: #EEEEEE">
     <td>@translated_messages.message_key@</td>
     <td>@translated_messages.default_message@</td>
     <td>@translated_messages.translated_message@</td>
     <td>(<span class="edit-anchor"><a href="edit-localized-message?message_key=@translated_messages.escaped_key@&locales=@translated_messages.escaped_language@&package_key=@package_key@&translated_p=1">edit</a></span>)</td>
    </tr>
    </multiple>
   </table>
  </td>
 </tr>
</table>

</else>

</div>
