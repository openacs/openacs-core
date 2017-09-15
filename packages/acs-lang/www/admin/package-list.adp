<master>
 <property name="doc(title)">@page_title;literal@</property>
 <property name="context">@context;literal@</property>

<formtemplate id="search">
<p>Search <formwidget id="search_locale"> for <formwidget id="q"> <input type="submit" value="Search">
</formtemplate>

<include src="/packages/acs-lang/lib/conflict-link" locale="@current_locale;literal@" >

<if @locale_enabled_p;literal@ true and @site_wide_admin_p;literal@ true>
  <ul class="action-links">
    <li><a href="@import_all_url@" title="#acs-lang.Import_all_messages__title#">#acs-lang.Import_all_messages_for_this_locale#</a></li>
    <li> <a href="@export_all_url@" title="#acs-lang.Export_all_messages__title#">#acs-lang.Export_all_messages_for_this_locale#</a></li>
  </ul>
</if>

<table cellpadding="0" cellspacing="0" border="0">
  <tr>
    <td style="background: #CCCCCC">

      <table cellpadding="4" cellspacing="1" border="0">
        <tr valign="middle" style="background: #FFFFE4">
          <th></th>
          <th>#acs-lang.Package#</th>
          <th>#acs-lang.Translated#</th>
          <th>#acs-lang.Untranslated#</th>
          <th>#acs-lang.Total#</th>
        </tr>
        <multiple name="packages">
          <tr style="background: #EEEEEE">
            <td>
              <a href="@packages.batch_edit_url@" title="Batch edit all messages in this @packages.package_key@"><img src="/shared/images/Edit16.gif" alt="edit" width="16" height="16"></a>
            </td>
            <td>
              <a href="@packages.view_messages_url@" title="View all messages in package">@packages.package_key@</a>
            </td>
            <td align="right">
              <if @packages.num_translated_pretty@ ne 0>
                <a href="@packages.view_translated_url@" title="View all translated messages in package">@packages.num_translated_pretty@</a>
              </if>
            </td>
            <td align="right">
              <if @packages.num_untranslated_pretty@ ne 0>
                <a href="@packages.view_untranslated_url@" title="View all untranslated messages in package">@packages.num_untranslated_pretty@</a>
              </if>
            </td>
            <td align="right">
              <if @packages.num_messages_pretty@ ne 0>
                <a href="@packages.view_messages_url@" title="View all messages in package">@packages.num_messages_pretty@</a>
                </if>
            </td>
          </tr>
        </multiple>
      </table>

    </td>
  </tr>
</table>
