<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>
  <property name="focus">@focus;noquote@</property>

<if @recover_info.password_message@ nil>
  <p> Enter your username to begin password recovery. </p>
  <formtemplate id="recover"></formtemplate>
</if>
<else>
  @recover_info.password_message@
  <p> To log in, visit the <a href="@login_url@">login page</a>. </p>
</else>

