<master>
  <property name="doc(title)">@instance_name;literal@</property>
  <property name="context_bar">@context_bar;literal@</property>

<if @admin_p@>
  <div style="float: right;">
    <a href="admin" class="button">#acs-kernel.common_Administration#</a>
  </div>
</if>

<include src="/packages/acs-lang/www/change-locale-include" return_url="@return_url;noquote@" return_p="@return_p;noquote@">