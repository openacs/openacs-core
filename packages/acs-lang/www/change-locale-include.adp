Locale for this request: <%= [ad_conn locale] %><br />

<table width="100%">
<tr>
<td>
<formtemplate id="locale_form"></formtemplate>
</td>

<!-- Cannot use this stuff as not all message keys have been looked up at this point
<if @message_debug_html@ not nil>
<td>
Using message Keys:
<p>
@message_debug_html@
</p>
</td>
</if>
-->
</tr>
</table>