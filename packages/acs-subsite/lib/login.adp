<formtemplate id="login" style="standard-lars"></formtemplate>

<if @forgotten_pwd_url@ not nil>
  <a href="@forgotten_pwd_url@">Forgot your password?</a> <br />
</if>

<if @register_url@ not nil>
  <a href="@register_url@">Register</a>
</if>
