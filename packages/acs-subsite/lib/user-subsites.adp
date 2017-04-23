  <if @groups:rowcount@ gt 0> 
  <h2>#acs-subsite.You_are_in_the_follow#</h2>
  <ul>
    <multiple name="groups">
      <li> @groups.group_name@
      <if @groups.admin_p;literal@ true>&nbsp;[<a href="@groups.admin_url@">#acs-kernel.common_Administration#</a>]</if></li>
    </multiple>
  </ul>
  </if>