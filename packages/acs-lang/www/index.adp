<master>
  <property name="title">@instance_name;noquote@</property>
  <property name="context_bar">@context_bar;noquote@</property>

<if @admin_p@>
  <a href="admin">Administration</a>
</if>

<blockquote>
<include src="/packages/acs-lang/www/change-locale-include" return_url="@return_url;noquote@" return_p="@return_p;noquote@">
</blockquote>
