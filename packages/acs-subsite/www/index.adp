<master>
<property name="context">@context;noquote@</property>

<if @user_id@ ne 0 and @main_site_p@ false>
  <div style="float: right;">
    <if @group_member_p@ true>
      <span class="button"><a href="group-leave" class="button" title="Leave this community">Leave community</a></span>
    </if>
    <else>
      <if @can_join_p@ true>
        <if @group_join_policy@ eq "open">
          <span class="button"><a href="group-join" class="button" title="Join this community">Join community</a></span>
        </if>
        <else>
          <span class="button"><a href="group-join" class="button" title="Request membership of this community">Request membership</a></span>
        </else>
      </if>
    </else>
  </div>
</if>

<table width="100%">
  <tr>
    <td valign="top">
      <h2>Applications</h2>
      <ul>
       <if @nodes:rowcount@ eq 0> 
        <li>(no packages)</li>
       </if>
       <else>
        <multiple name="nodes">
          <li><a href="@nodes.url@">@nodes.name@</a></li>
        </multiple>
       </else>

       <if @admin_p@ eq 1> 
        <p>
         <li> <a href="admin/">@subsite_name@ Administration</a></li>
        </p>
       </if>
      </ul>
    </td>
    <td valign="top">
      <h2>@communities_label@</h2>
      <include src="/packages/acs-subsite/lib/subsites">
    </td>
  </tr>
</table>
  

