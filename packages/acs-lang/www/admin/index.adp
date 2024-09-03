<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<include src="/packages/acs-lang/lib/conflict-link" >

<h1>@page_title@</h1>

<h2>#acs-lang.Actions#</h2>
<ul class="action-links">
  <li>#acs-lang.Toggle_translator_mode#: 
    <if @translator_mode_p;literal@ true><strong>#acs-lang.On#</strong> | <a href="translator-mode-toggle">#acs-lang.Off#</a></if>
    <else><a href="translator-mode-toggle">#acs-lang.On#</a> | <strong>#acs-lang.Off#</strong></else>
  </li>

  <li><a href="@parameter_url@">#acs-lang.Change_system_locale#</a>: #acs-lang.Current_system_locale_is#</li>
  <li><a href="set-system-timezone">#acs-lang.Change_system_timezone#</a>: #acs-lang.Current_system_timezone_is#</li>

<li><a href="lookup">#acs-lang.Look_up_message#</a></li>
<li><a href="edit-history?locale=@system_locale@">#acs-lang.Edit_history#</a></li>

<if @site_wide_admin_p;literal@ true>
  <li><a href="@import_url@" title="#acs-lang.Imports_messages_system-wide_from_catalog_files#" id="action-import">#acs-lang.Import_all_messages#</a></li>
  <li><a href="@export_url@" title="#acs-lang.Export_messages_system-wide_to_catalog_files#" id="action-export">#acs-lang.Export_all_messages#</a></li>
</if>

</ul>

<h2>#acs-lang.Installed_Locales#</h2>

<listtemplate name="locales"></listtemplate>