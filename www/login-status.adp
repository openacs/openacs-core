<div style="float: right; text-align: center; background-color: #dddddd; padding: 8px; border: 1px solid #bbbbbb; font-size: 85%;">
  <if @user_id@ eq 0>
    Not logged in<br>
    <a href="@login_url@">Login or register</a>
  </if>
  <else>
    @user_name@<br>
    <if @pvt_home_url@ not nil>
      <a href="@pvt_home_url@">@pvt_home_name@</a>
    </if>
    <else>
      @pvt_home_name@
    </else>
    - 
    <a href="@logout_url@">Logout</a>
  </else>
</div>
