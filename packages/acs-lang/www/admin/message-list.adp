<master>
  <property name="title">@page_title@</property>
  <property name="context">@context;noquote@</property>

<p>
  Show: 
  <multiple name="show_opts">
    <if @show_opts.rownum@ gt 1> | </if>
    <if @show_opts.selected_p@><b>@show_opts.label@ (@show_opts.count@)</b> </if>
    <else><a href="@show_opts.url@">@show_opts.label@ (@show_opts.count@)</a> </else>
  </multiple>
</p>

<include src="/packages/acs-lang/lib/conflict-link" locale="@current_locale@" package_key="@package_key@"/>

<if @create_p@ true>
  <p>
    <b>&raquo;</b> <a href="@new_message_url@">Create new message</a>
  </p>
</if>

<if @messages:rowcount@ eq 0>
  <i>No messages</i>
</if>
<else>
  <p>
    <b>&raquo;</b> <a href="@batch_edit_url@">Batch edit these messages</a>
  </p>

  <if @site_wide_admin_p@>
    <p>
      <b>&raquo;</b> <a href="@import_messages_url@">Import messages from catalog files</a>
    </p>
    <p>
      <b>&raquo;</b> <a href="@export_messages_url@">Export messages to catalog files</a>
    </p>
  </if>

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
            <if @create_p@ true>
              <th></th>
            </if>
          </tr>
          <multiple name="messages">
            <tr style="background: #EEEEEE">
              <td>
                <a href="@messages.edit_url@" title="Edit or comment on translation"><img src="/shared/images/Edit16.gif" border="0" width="16" height="16"></a>
              </td>
              <td>
                <a href="@messages.edit_url@" title="Edit or comment on translation">@messages.message_key_pretty@</a>
              </td>
              <td>@messages.default_message@</td>
              <if @default_locale@ ne @current_locale@>
                <td>                  
                  <if @messages.deleted_p@>
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
                  <a href="@messages.delete_url@" title="Delete this messages"><img src="/shared/images/Delete16.gif" border="0" width="16" height="16"></a>
                </td>
             </if>
            </tr>
          </multiple>
        </table>
      </td>
    </tr>
  </table>
</else>
