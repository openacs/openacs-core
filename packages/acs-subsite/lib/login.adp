<property name="focus">@focus;literal@</property>

<div id="register-login">
<formtemplate id="login"></formtemplate>

<if @forgotten_pwd_url@ not nil>
  <if @email_forgotten_password_p;literal@ true>
  <a href="@forgotten_pwd_url;literal@" true>#acs-subsite.Forgot_your_password#</a>
  <br>
  </if>
</if>

<if @self_registration;literal@ true>

<if @register_url@ not nil>
  <a href="@register_url@">#acs-subsite.Register#</a>
</if>

</if>
</div>
