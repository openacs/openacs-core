<table cellpadding="0" cellspacing="0" border="0">
 <tr>
  <td style="background: #CCCCCC">
   <table cellpadding="4" cellspacing="1" border="0">
    <tr style="background: #FFFFe4">
     <th>Locale</th>
     <th>Label</th>
     <th>Enabled</th>
     <th>Default Locale For Langauge</th>
     <th>Action</th>
    </tr>
    <multiple name="locales">
     <tr style="background: #EEEEEE">
      <td>@locales.locale@</td>
      <td>
        <a href="@locales.msg_edit_url@" title="Edit localized messages for @locales.locale_label@">@locales.locale_label@</a>
      </td>
      <td align="center">
        <if @locales.enabled_p@ eq f>
           No
         </if>
         <else>
           Yes
         </else>
      </td>
      <td align="center">
          <if @locales.default_p@ eq "t">
            <if @locales.num_locales_for_language@ eq 1>
              <span style="font-style: italic; color: gray;" title="This is the only locale for this language">N/A</span>
            </if>
            <else>
              <b>Yes</b>
            </else>
          </if>
          <else>No (<a href="@locales.locale_make_default_url@"><span class="small">make default</span></a>)</else>
      </td>
      <td>
         (<a href="@locales.msg_edit_url@">edit messages</a>)&nbsp;
         (<a href="@locales.locale_edit_url@">edit locale</a>)&nbsp;
         (<a href="@locales.locale_delete_url@">delete locale</a>)
         <if @locales.enabled_p@ eq f>
           (<a href="@locales.locale_enabled_p_url@">enable locale</a>)
         </if>
         <else>
           (<a href="@locales.locale_enabled_p_url@">disable locale</a>)
         </else>
      </td>
     </tr>
    </multiple>
   </table>
  </td>
 </tr>
</table>
<p>(<a href="locale-new">Create New Locale</a>)</p>
