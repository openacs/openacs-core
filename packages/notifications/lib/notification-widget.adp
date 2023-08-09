<if @sub_url@ not nil>
  <a class="notifications-@type@" href="@sub_url@" title="@title@">
    <adp:icon name="bell"> @sub_chunk@
  </a>
  <if @subscribers_url@ not nil>
    [<a class="notifications-@type@" href="@subscribers_url;noi18n@">#notifications.Subscribers#</a>]
  </if>
</if>
