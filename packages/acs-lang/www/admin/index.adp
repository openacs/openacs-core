<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>

<include src="/packages/acs-lang/lib/conflict-link" />

<ul class="action-links">
  <li>Toggle translator mode: 
    <if @translator_mode_p@ true><b>On</b> | <a href="translator-mode-toggle">Off</a></if>
    <else><a href="translator-mode-toggle">On</a> | <b>Off</b></else>
  </li>

  <li><a href="@parameter_url@">Change system locale</a>: Current system locale is <b>@system_locale_label@ [ @system_locale@ ]</b></li>

<if @timezone_p@>
  <li><a href="set-system-timezone">Change system timezone</a>: Current system timezone is <b>@timezone@</b></li>
</if>

<li><a href="lookup">Look up message</a></li>

<if @site_wide_admin_p@>
  <li><a href="@import_url@" title="Imports messages system-wide from catalog files" onclick="return confirm('Are you sure you want to import all I18N messages from catalog files?');">Import all messages</a></li>
  <li><a href="@export_url@" title="Export messages system-wide to catalog files" onclick="return confirm('Are you sure you want to export all I18N messages to catalog files?');">Export all messages</a></li>
</if>

</ul>

<h2>Installed Locales</h2>

<table cellpadding="0" cellspacing="0" border="0">
 <tr>
  <td style="background: #CCCCCC">
   <table cellpadding="4" cellspacing="1" border="0">
    <tr style="background: #FFFFe4">
     <th></th>
     <th>Locale</th>
     <th>Label</th>
     <th>Translated</th>
     <th>Untranslated</th>
     <th>Enabled</th>
     <th>Default Locale For Language</th>
     <th></th>
    </tr>
    <multiple name="locales">
     <tr style="background: #EEEEEE">
      <td><a href="@locales.locale_edit_url@" title="Edit definition of locale"><img src="/shared/images/Edit16.gif" border="0" width="16" height="16"></a></td>
      <td>@locales.locale@</td>
      <td>
        <a href="@locales.msg_edit_url@" title="Edit localized messages for @locales.locale_label@">@locales.locale_label@</a>
      </td>
      <td align="right"><if @locales.num_translated_pretty@ ne 0>@locales.num_translated_pretty@</if></td>
      <td align="right"><if @locales.enabled_p@ true or @locales.num_translated@ gt 0><if @locales.num_untranslated_pretty@ ne 0>@locales.num_untranslated_pretty@</if></if></td>
      <td align="center">
        <if @locales.enabled_p@ true>
          <a href="@locales.locale_enabled_p_url@" title="Disable this locale"><img src="/resources/acs-subsite/checkboxchecked.gif" height="13" width="13" border="0" style="background-color: white;"></a>
        </if>
        <else>
          <a href="@locales.locale_enabled_p_url@" title="Enable this locale"><img src="/resources/acs-subsite/checkbox.gif" height="13" width="13" border="0" style="background-color: white;"></a>
        </else>
      </td>
      <td align="center">
          <if @locales.default_p@ eq "t">
            <if @locales.num_locales_for_language@ eq 1>
              <span style="font-style: italic; color: gray;" title="This is the only locale for this language"></span>
            </if>
            <else>
              @locales.language@: <img src="/shared/images/radiochecked" height="13" width="13" border="0">
            </else>
          </if>
          <else>@locales.language@: <a href="@locales.locale_make_default_url@" title="Make this locale the default locale for language '@locales.language@'"><img src="/shared/images/radio" height="13" width="13" border="0"></a></else>
      </td>
      <td>
        <a href="@locales.locale_delete_url@" title="Delete this locale"><img src="/shared/images/Delete16.gif" border="0" width="16" height="16"></a>
      </td>
     </tr>
    </multiple>
   </table>
  </td>
 </tr>
</table>

<ul class="action-links">
  <li><a href="locale-new">Create New Locale</a></li>
</ul>
