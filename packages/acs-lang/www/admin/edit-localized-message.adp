<master src="master">
 <property name="title">Edit a message</property>
 <property name="header_stuff">@header_stuff@</property>

<h2>Edit Localized Messages</h2>
@context_bar@

<hr />

<div>

<if @locale_label@ nil>

  <p class="error">Please, submit a valid locale.</p>

</if>
<else>

  <p>Locale: <strong>@locale_label@</strong> [ <tt>@locale_user@</tt> ]</p>
  <p>Key: <span style="background: #CCFFCC"><strong>@key@</strong></span></p>

<formtemplate id="message_editing"></formtemplate>

</else>

</div>
