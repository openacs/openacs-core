<master>
  <property name="title">@instance_name@</property>
  <property name="context_bar">@context_bar@</property>

<if @admin_p@>
  <a href="admin">Administration</a>
</if>

<blockquote>
<include src="/packages/acs-lang/www/change-locale-include" return_url="@return_url@" return_p="@return_p@">
</blockquote>
