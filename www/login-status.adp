<div style="float: right; text-align: center; background-color: #dddddd; padding: 8px; border: 1px solid #bbbbbb; font-size: 85%;">
  <if @user_id@ eq 0>#acs-subsite.Not_logged_in#<br>
    <a href="@login_url@">#acs-subsite.Login_or_register#</a>
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
    <a href="@logout_url@">#acs-subsite.Logout#</a>
  </else>
</div>
