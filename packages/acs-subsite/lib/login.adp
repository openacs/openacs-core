<property name="focus">@focus;noquote@</property>

<div id="register-login">
<formtemplate id="login"></formtemplate>

<if @forgotten_pwd_url@ not nil>
  <if @email_forgotten_password_p@ true>
  <a href="@forgotten_pwd_url@">#acs-subsite.Forgot_your_password#</a>
  <br />
  </if>
</if>

<if @self_registration@ true>

<p />
<if @register_url@ not nil>
  <a href="@register_url@">#acs-subsite.Register#</a>
</if>

</if>
</div>-