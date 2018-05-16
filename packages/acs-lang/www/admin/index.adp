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

<if @timezone_p;literal@ true>
  <li><a href="set-system-timezone">#acs-lang.Change_system_timezone#</a>: #acs-lang.Current_system_timezone_is#</li>
</if>

<li><a href="lookup">#acs-lang.Look_up_message#</a></li>

<if @site_wide_admin_p;literal@ true>
  <li><a href="@import_url@" title="#acs-lang.Imports_messages_system-wide_from_catalog_files#" id="action-import">#acs-lang.Import_all_messages#</a></li>
  <li><a href="@export_url@" title="#acs-lang.Export_messages_system-wide_to_catalog_files#" id="action-export">#acs-lang.Export_all_messages#</a></li>
</if>

</ul>

<h2>#acs-lang.Installed_Locales#</h2>

<table cellpadding="0" cellspacing="0" border="0">
 <tr>
  <td style="background: #CCCCCC">
   <table cellpadding="4" cellspacing="1" border="0">
    <tr style="background: #FFFFe4">
     <th></th>
     <th>#acs-lang.Locale#</th>
     <th>#acs-lang.Label#</th>
     <th>#acs-lang.Translated#</th>
     <th>#acs-lang.Untranslated#</th>
     <th>#acs-lang.Enabled#</th>
     <th>#acs-lang.Default_Locale_For_Language#</th>
     <th></th>
    </tr>
    <multiple name="locales">
     <tr style="background: #EEEEEE">
      <td><a href="@locales.locale_edit_url@" title="#acs-lang.Edit_definition_of_locale#"><img src="/shared/images/Edit16.gif" style="border:0;" width="16" height="16" alt="#acs-lang.Edit_definition_of_locale#"></a></td>
      <td>@locales.locale@</td>
      <td>
        <a href="@locales.msg_edit_url@" title="#acs-lang.Edit_localized_messages_for#">@locales.locale_label@</a>
      </td>
      <td align="right"><if @locales.num_translated_pretty;literal@ ne 0>@locales.num_translated_pretty@</if></td>
      <td align="right"><if @locales.enabled_p;literal@ true or @locales.num_translated;literal@ gt 0><if @locales.num_untranslated_pretty;literal@ ne 0>@locales.num_untranslated_pretty@</if></if></td>
      <td align="center">
        <if @locales.enabled_p;literal@ true>
          <a href="@locales.locale_enabled_p_url@" title="#acs-lang.Disable_this_locale#"><img src="/resources/acs-subsite/checkboxchecked.gif" height="13" width="13" style="border:0; background-color: white;" alt="#acs-lang.Disable_this_locale#"></a>
        </if>
        <else>
          <a href="@locales.locale_enabled_p_url@" title="#acs-lang.Enable_this_locale#"><img src="/resources/acs-subsite/checkbox.gif" height="13" width="13" style="border:0; background-color: white;" alt="#acs-lang.Enable_this_locale#"></a>
        </else>
      </td>
      <td align="center">
          <if @locales.default_p;literal@ true>
            <if @locales.num_locales_for_language;literal@ eq 1>
              <span style="font-style: italic; color: gray;" title="#acs-lang.This_is_the_only_locale_for_this_language#"></span>
            </if>
            <else>
              @locales.language@: <img src="/shared/images/radiochecked.gif" height="13" width="13" style="border:0;" alt="#acs-lang.Default_Locale_For_Language#">
            </else>
          </if>
          <else>@locales.language@: <a href="@locales.locale_make_default_url@" title="#acs-lang.Make_this_locale_the_default_locale_for_language#"><img src="/shared/images/radio.gif" height="13" width="13" style="border:0;" alt="#acs-lang.Make_this_locale_the_default_locale_for_language#"></a></else>
      </td>
      <td>
        <a href="@locales.locale_delete_url@" title="#acs-lang.Delete_this_locale#"><img src="/shared/images/Delete16.gif" style="border:0;" width="16" height="16" alt="#acs-lang.Delete_this_locale#"></a>
      </td>
     </tr>
    </multiple>
   </table>
  </td>
 </tr>
</table>

<ul class="action-links">
  <li><a href="locale-new">#acs-lang.Create_New_Locale#</a></li>
</ul>
