<master src="master">
<property name="title">Edit a message</property>

<h2>New Localized Messages - Upload a file</h2>

@context_bar@

<hr />

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
