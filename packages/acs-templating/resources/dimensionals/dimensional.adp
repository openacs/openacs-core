<table class="dimensional dimensional-table" border="0" cellspacing="0" cellpadding="3" width="100%">
<tr><multiple name="dimensional"><th>@dimensional.label@</th><group column="key"></group>
</multiple></tr>
<tr><multiple name="dimensional">
<td>[<group column="key">
<if @dimensional.selected@ true><strong>@dimensional.group_label@</strong></if><else><a href="@dimensional.href@">@dimensional.group_label@</a></else><if @dimensional.groupnum_last_p;literal@ false> | </if>
</group>]</td>
</multiple></tr>
</table>

