<master src="master">
 <property name="title">Edit a message</property>

<h2>New Localized Messages</h2>

@context_bar@

<hr />

<div>

<if @locale_label@ nil>

  <p class="error">Please, submit a valid locale.</p>

</if>
<else>

  <p>Locale: <strong>@locale_label@</strong> [ <tt>@locale_user@</tt> ]</p>

  <formtemplate id="message_new"></formtemplate>

</else>

</div>
