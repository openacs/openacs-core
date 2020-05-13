<if @sub_url@ not nil>
<a class="notifications-@type@" href="@sub_url@" title="@title@"><img src="@icon;noi18n@" alt="@icon_alt@" style="border:0">&nbsp;@sub_chunk@</a>
<if @subscribers_url@ not nil>
[<a class="notifications-@type@" href="@subscribers_url;noi18n@">#notifications.Subscribers#</a>]
</if>
</if>