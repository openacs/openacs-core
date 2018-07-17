<td>[<multiple name="opt">
<if @opt.current@ eq 1><strong>@opt.label@</strong></if><else><a href="@opt.href@">@opt.label@</a></else><if @opt:rowcount;literal@ ne @opt.count@> | </if></multiple>]</td>