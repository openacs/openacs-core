<property name="focus">@focus;noquote@</property>

<formtemplate id="login"></formtemplate>

<if @forgotten_pwd_url@ not nil>
  <a href="@forgotten_pwd_url@">#acs-subsite.Forgot_your_password#</a> <br />
</if>

<if @self_registration@ true>

<p />
<if @register_url@ not nil>
  <a href="@register_url@">#acs-subsite.Register#</a>
</if>

</if>
