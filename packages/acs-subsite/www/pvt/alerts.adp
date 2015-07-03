<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<if @discussion_forum_alert_p@ eq 1>

<h3>#acs-subsite.Your_discussion_alerts#</h3>

<blockquote>
   <table>
   <tr><th>#acs-subsite.Status#</th>
       <th>#acs-subsite.Action#</th>
       <th>#acs-subsite.Topic#</th>
       <th>#acs-subsite.Frequency#</th>
     <if @bboard_keyword_p@ eq 1>
       <th>#acs-subsite.Keyword#</th>
     </if>
   </tr>

 <multiple name=bboard_rows>
   <tr>
      <if @status@ eq "enabled">
       <td><font color="red">#acs-subsite.Enabled#</font></td>
       <td><a href="@action_url@">#acs-subsite.Disable#</a></td>
      </if>
      <else>
       <td>#acs-subsite.Disabled#</td>
       <td><a href="@action_url@">#acs-subsite.Re_enable#</a></td>
      </else>
       <td>@topic@</td>
       <td>@frequency@</td>
     <if @bboard_keyword_p@ eq 1>
       <td>@keyword@</td>
     </if>
   </tr>
 </multiple>

   </table>
</blockquote> 

</if>

<if @classified_email_alert_p@ eq 1>

<h3>#acs-subsite.Your_system_alerts#</h3>

<blockquote>
   <table border>
   <tr><th>#acs-subsite.Status#</th>
       <th>#acs-subsite.Action#</th>
       <th>#acs-subsite.Domain#</th>
       <th>#acs-subsite.Expires#</th>
       <th>#acs-subsite.Frequency#</th>
       <th>#acs-subsite.Alert_Type#</th>
       <th>#acs-subsite.type_specific_info#</th>
   </tr>
   
 <multiple name=classified_rows>

   <tr><td>@status@</td>
       <td>@action@</td>
       <td>@domain@</td>
       <td><a href="/gc/alert-extend?rowid=@rowid@">@expires@</a></td>
       <td>@frequency@</td>
       <td>@alert_type@</td>
       <td>@alert_value@</td>
   </tr>
     
 </multiple>
   </table>
</blockquote>

</if>

<if @discussion_forum_alert_p@ eq 0 and @classified_email_alert_p@ eq 0>
 #acs-subsite.You_have_no_email_alerts#
</if>

