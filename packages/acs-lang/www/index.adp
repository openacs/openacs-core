<master>
  <property name="title">@instance_name;noquote@</property>
  <property name="context_bar">@context_bar;noquote@</property>

<if @admin_p@>
  <div style="float: right;">
    <a href="admin" class="button">#acs-kernel.common_Administration#</a>
  </div>
</if>

<include src="/packages/acs-lang/www/change-locale-include" return_url="@return_url;noquote@" return_p="@return_p;noquote@">