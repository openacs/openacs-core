<master>
<property name="context">@context;noquote@</property>

<if @user_id@ ne 0>
  <div style="float: right;">
    <if @main_site_p@ false>  
      <if @group_member_p@ true>
        <span class="button"><a href="group-leave" class="button" title="Leave this community">Leave community</a></span>
      </if>
      <else>
        <if @can_join_p@ true>
          <if @group_join_policy@ eq "open">
            <a href="group-join" class="button" title="Join this community">Join community</a>
          </if>
          <else>
            <a href="group-join" class="button" title="Request membership of this community">Request membership</a>
          </else>
        </if>
      </else>
    </if>
    <if @admin_p@ true> 
      <a href="admin/" class="button" title="Administer @subsite_name@">Admin</a>
    </if>
  </div>
</if>

<table width="100%">
  <tr>
    <td valign="top">
      <h2>Applications</h2>
      <include src="/packages/acs-subsite/lib/applications">
    </td>
    <td valign="top">
      <h2>@communities_label@</h2>
      <include src="/packages/acs-subsite/lib/subsites">
    </td>
  </tr>
  <if @show_members_page_link_p@>
  <tr>
    <td valign="top" colspan="2">
      <p> <b>&raquo;</b> <a href="members/">Members</a> </p>
    </td>
  </tr>
  </if>
</table>
  

