<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>
  <property name="focus">@focus;noquote@</property>

<if @recover_info.password_message@ nil>
  <p> #acs-subsite.Enter_your_username_to# </p>
  <formtemplate id="recover"></formtemplate>
</if>
<else>
  @recover_info.password_message@
  <p> #acs-subsite.To_log_in_visit_the# <a href="@login_url@">#acs-subsite.login_page#</a>. </p>
</else>


