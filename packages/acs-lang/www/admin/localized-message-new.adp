<master src="master">
 <property name="title">New Localized Messages</property>
 <property name="context_bar">@context_bar@</property>

<div>

<if @locale_label@ nil>

  <p class="error">Please, submit a valid locale.</p>

</if>
<else>

  <p>Locale: <strong>@locale_label@</strong> [ <tt>@locale_user@</tt> ]</p>

  <formtemplate id="message_new"></formtemplate>

</else>

</div>
