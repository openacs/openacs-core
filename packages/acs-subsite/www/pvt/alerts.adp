<master>
<property name=title>@title@</property>
<property name="context">@context@</property>

<if @discussion_forum_alert_p@ eq 1>

<h3>Your discussion forum alerts</h3>

<blockquote>
   <table>
   <tr><th>Status</th>
       <th>Action</th>
       <th>Topic</th>
       <th>Frequency</th>
     <if @bboard_keyword_p@ eq 1>
       <th>Keyword</th>
     </if>
   </tr>

 <multiple name=bboard_rows>
   <tr>
      <if @status@ eq "enabled">
       <td><font color="red">Enabled</font></td>
       <td><a href="@action_url@">Disable</a></td>
      </if>
      <else>
       <td>Disabled</td>
       <td><a href="@action_url@">Re-enable</a></td>
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

<h3>Your @gc_system_name@ alerts</h3>

<blockquote>
   <table border>
   <tr><th>Status</th>
       <th>Action</th>
       <th>Domain</th>
       <th>Expires</th>
       <th>Frequency</th>
       <th>Alert Type</th>
       <th>type-specific info</th>
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
 You currently have no email alerts registered.
</if>
