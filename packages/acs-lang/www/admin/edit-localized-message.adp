<master src="master">
 <property name="title">Edit a message</property>
 <property name="header_stuff">@header_stuff;noquote@</property>
 <property name="context_bar">@context_bar;noquote@</property>

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

<p>
  <b>&raquo;</b> <a href="@lookups_url@">Show message key usage</a>
</p>

<include src="audit-include" current_locale="@current_locale;noquote@" message_key="@message_key;noquote@" package_key="@package_key;noquote@">
