  <if @groups:rowcount;literal@ gt 0>
  <h2>#acs-subsite.You_are_in_the_follow#</h2>
  <ul>
    <multiple name="groups">
      <li><if @groups.url@ not nil><a href="@groups.url@">@groups.group_name@</a></if><else>@groups.group_name@</else>
      <if @groups.member_state;literal@ ne "approved">&nbsp;(@groups.member_state_pretty@)&nbsp;</if>
      <if @groups.admin_p;literal@ true>&nbsp;[<a href="@groups.admin_url@">#acs-kernel.common_Administration#</a>]</if></li>
    </multiple>
  </ul>
  </if>