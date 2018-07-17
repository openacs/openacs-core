<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>
  <property name="focus">search.q</property>

<formtemplate id="search">
Search <formwidget id="search_locale"> for <formwidget id="q"> <input type="submit" value="Search">
</formtemplate>

<if @submit_p;literal@ true>
  <h2>Search Results</h2>

  <if @other_search_url@ not nil>
    <ul class="action-links">
      <li><a href="@other_search_url@">Search for '@q@' in @other_locale@</a></li>
    </ul>
  </if>
   
  <if @messages:rowcount;literal@ gt 0>        
    <table cellpadding="0" cellspacing="0" border="0">
      <tr>
        <td style="background: #CCCCCC">
          <table cellpadding="4" cellspacing="1" border="0">
            <tr style="background: #FFFFe4">
              <th></th>
              <th>Package</th>
              <th>Message Key</th>
              <th>@default_locale_label@ Message</th>
              <if @default_locale@ ne @current_locale@>
                <th>@locale_label@ Message</th>
              </if>
            </tr>
            <multiple name="messages">
              <tr style="background: #EEEEEE">
                <td>
                  <a href="@messages.edit_url@" title="Edit or comment on translation"><img src="/shared/images/Edit16.gif" border="0" width="16" height="16"></a>
                </td>
                <td><a href="@messages.package_url@">@messages.package_key@</a></td>
                <td><a href="@messages.edit_url@" title="Edit or comment on translation">@messages.message_key_pretty@</a></td>
                <td>@messages.default_message@</td>
                <if @default_locale@ ne @current_locale@>
                  <td>
                    <if @messages.translated_message@ not nil>@messages.translated_message@</if>
                    <else><span style="color: gray; font-style: italic;">Not translated</span></else>
                  </td>
                </if>
              </tr>
            </multiple>
         </table>
        </td>
      </tr>
    </table>
  </if>
  <else>
    <em>No messages found.</em>
  </else>
</if>
