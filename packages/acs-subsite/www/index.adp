<master>
<property name="context">@context;noquote@</property>

<if @user_id@ ne 0>
  <div style="float: right;">
    <if @main_site_p@ false>  
      <if @group_member_p@ true>
        <span class="button"><a href="group-leave" class="button"
          title="#acs-subsite.Leave_this_subsite#">#acs-subsite.Leave_subsite#</a></span>
      </if>
      <else>
        <if @can_join_p@ true>
          <if @group_join_policy@ eq "open">
            <a href="register/user-join" class="button"
              title="#acs-subsite.Join_this_subsite">#acs-subsite.Join_subsite#</a>
          </if>
          <else>
            <a href="register/user-join" class="button"
              title="#acs-subsite.Req_membership_subs#">#acs-subsite.Request_membership#</a>
          </else>
        </if>
      </else>
    </if>
    <if @admin_p@ true> 
      <a href="admin/" class="button" title="#acs-subsite.Administer_subsite#">#acs-subsite.Admin#</a>
    </if>
  </div>
</if>

<table width="100%">
  <tr>
    <td valign="top">
      <h2>#acs-subsite.Applications#</h2>
      <include src="/packages/acs-subsite/lib/applications">
    </td>
    <td valign="top">
      <h2>#acs-subsite.Subsites#</h2>
      <include src="/packages/acs-subsite/lib/subsites">
    </td>
  </tr>
  <if @show_members_page_link_p@>
  <tr>
    <td valign="top" colspan="2">
      <p> <b>&raquo;</b> <a href="members/">#acs-subsite.Members#</a> </p>
    </td>
  </tr>
  </if>
</table>
  

