  <if @groups:rowcount@ gt 0> 
  <h2>#acs-subsite.You_are_in_the_follow#</h2>
  <ul>
    <multiple name="groups">
      <li> <a href="@groups.url@">@groups.group_name@</a><if @groups.admin_p@ true>&nbsp;[<a href="@groups.url@admin/">#acs-kernel.common_Administration#</a>]</if></li>
    </multiple>
  </ul>
  </if>