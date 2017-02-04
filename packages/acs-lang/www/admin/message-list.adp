<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>
  <div style="float: right;">
    <formtemplate id="locale_form">
      @form_vars;noquote@
      <table cellspacing="2" cellpadding="2" border="0">
        <tr class="form-element"><td class="form-label">Language</td>
        <td class="form-widget"><formwidget id="locale"></td></tr>
        <tr class="form-element">
        <td align="left" colspan="2"><formwidget id="formbutton:ok"></td></tr>
      </table>
    </formtemplate>
  </div>

<p>
  Show: 
  <multiple name="show_opts">
    <if @show_opts.rownum@ gt 1> | </if>
    <if @show_opts.selected_p;literal@ true><strong>@show_opts.label@ (@show_opts.count@)</strong> </if>
    <else><a href="@show_opts.url@">@show_opts.label@ (@show_opts.count@)</a> </else>
  </multiple>
</p>

<include src="/packages/acs-lang/lib/conflict-link" locale="@current_locale;literal@" package_key="@package_key;literal@">

<ul class="action-links">
  <if @create_p;literal@ true>
    <li><a href="@new_message_url@">Create new message</a></li>
  </if>

  <if @messages:rowcount@ eq 0>
    <em>No messages</em>
  </if>
  <else>
    <li><a href="@batch_edit_url@">Batch edit these messages</a></li>
    <if @site_wide_admin_p;literal@ true>
      <li><a href="@import_messages_url@">Import messages for this package and locale from catalog files</a></li>
      <li><a href="@export_messages_url@">Export messages for this package and locale to catalog files</a></li>
    </if>
  </else>
</ul>

<if @messages:rowcount@ gt 0>
  <table cellpadding="0" cellspacing="0" border="0">
    <tr>
      <td style="background: #CCCCCC">
        <table cellpadding="4" cellspacing="1" border="0">
          <tr style="background: #FFFFe4">
            <th></th>
            <th>Message Key</th>
            <th>@default_locale_label@ Message</th>
            <if @default_locale@ ne @current_locale@>
              <th>@locale_label@ Message</th>
            </if>
            <if @create_p;literal@ true>
              <th></th>
            </if>
          </tr>
          <multiple name="messages">
            <tr style="background: #EEEEEE">
              <td>
                <a href="@messages.edit_url@" title="Edit or comment on translation"><img src="/shared/images/Edit16.gif" width="16" height="16" alt="edit"></a>
              </td>
              <td>
                <a href="@messages.edit_url@" title="Edit or comment on translation">@messages.message_key_pretty@</a>
              </td>
              <td>@messages.default_message@</td>
              <if @default_locale@ ne @current_locale@>
                <td>                  
                  <if @messages.deleted_p;literal@ true>
                    <span style="color: red; font-style: italic;">DELETED</span> (@messages.translated_message@)
                  </if>
                  <else>
                    <if @messages.translated_message@ not nil>@messages.translated_message@</if>
                    <else><span style="color: gray; font-style: italic;">Not translated</span></else>
                  </else>
                </td>
              </if>
              <if @messages.translated_message@ not nil>
                <td>
                  <a href="@messages.delete_url@" title="Delete this messages"><img src="/shared/images/Delete16.gif" alt="delete" width="16" height="16"></a>
                </td>
             </if>
            </tr>
          </multiple>
        </table>
      </td>
    </tr>
  </table>
</if>
