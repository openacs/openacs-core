<master src="master">
<property name="title">New Localized Messages - Upload a file</property>
<property name="context_bar">@context_bar@</property>

<div>

<if @locale_label@ nil>

  <p class="error">Please, submit a valid locale.</p>

</if>
<else>

  <p>Locale: <strong>@locale_label@</strong> [ <tt>@locale_user@</tt> ]</p>

  <formtemplate id="message_file_upload"></formtemplate>

  <p style="font-size: 9pt; color: red;">The message has been modified to make it
  unique. Don't worry if it's not the same filename you will be uploading.</p>

</else>

</div>
