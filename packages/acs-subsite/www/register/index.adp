<master>
<property name="title">#acs-subsite.Log_In#</property>
<property name="focus">login.username</property>
<property name="context">{#acs-subsite.Log_In#}</property>

<formtemplate id="login" style="standard-lars"></formtemplate>

<if @forgotten_pwd_url@ not nil>
  <a href="@forgotten_pwd_url@">Forgot your password?</a>
</if>

