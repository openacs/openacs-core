<master src="master">
 <property name="title">Edit a message</property>
 <property name="header_stuff">@header_stuff@</property>
 <property name="context_bar">@context_bar@</property>

<div>

<if @locale_label@ nil>

  <p class="error">Please, submit a valid locale.</p>

</if>
<else>

  <p>Locale: <strong>@locale_label@</strong> [ <tt>@current_locale@</tt> ]</p>
  <p>Package: <span style="background: #CCFFCC"><strong>@package_key@</strong></span></p>
  <p>Key: <span style="background: #CCFFCC"><strong>@message_key@</strong></span></p>

<formtemplate id="message_editing"></formtemplate>

</else>

</div>
