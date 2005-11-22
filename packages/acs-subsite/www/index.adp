<master>
  <property name="context">@context;noquote@</property>
  <property name="title">@subsite_name;noquote@</property>


<table>
  <tr>
    <td valign="top">
      <div class="portlet">
        <h2>#acs-subsite.Applications#</h2>
        <div class="portlet-body">
          <include src="/packages/acs-subsite/lib/applications">
        </div>
      </div>
    </td>
    <td valign="top">
      <div class="portlet">
        <h2>#acs-subsite.Subsites#</h2>
        <div class="portlet-body">
          <include src="/packages/acs-subsite/lib/subsites">
        </div>
      </div>
    </td>
  </tr>

  <tr>
    <td valign="top" colspan="2">
      <div class="portlet">
        <if @show_members_page_link_p@>
          <a href="members/" class="button">#acs-subsite.Members#</a>
        </if>
	  <a href="site-map/" class="button">#acs-subsite.UserSiteMap#</a>
        <if @untrusted_user_id@ ne 0>
          <if @main_site_p@ false>  
            <if @group_member_p@ true>
              <a href="group-leave" class="button" title="#acs-subsite.Leave_this_subsite#">#acs-subsite.Leave_subsite#</a>
            </if>
            <else>
              <if @can_join_p@ true>
                <if @group_join_policy@ eq "open">
                  <a href="register/user-join" class="button" title="#acs-subsite.Join_this_subsite">#acs-subsite.Join_subsite#</a>
                </if>
                <else>
                  <a href="register/user-join" class="button" title="#acs-subsite.Req_membership_subs#">#acs-subsite.Request_membership#</a>
                </else>
              </if>
            </else>
          </if>
        </if>
        <if @admin_p@ true> 
          <a href="admin/" class="button" title="#acs-subsite.Administer_subsite#">#acs-kernel.common_Administration#</a>
        </if>
      </div>
    </td>
  </tr>
</table>
  

