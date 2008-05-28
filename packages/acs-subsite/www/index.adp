<master>
  <property name="context">@context;noquote@</property>
  <property name="title">@subsite_name;noquote@</property>


<table>
  <tr>
    <td valign="top">
      <div class="portlet-wrapper">
        <div class="portlet-header">
          <div class="portlet-title">
            <h1>#acs-subsite.Applications#</h1>
          </div>
        </div>
        <div class="portlet">
          <include src="/packages/acs-subsite/lib/applications">
        </div>
      </div>
    </td>
    <td valign="top">
      <div class="portlet-wrapper">
        <div class="portlet-header">
          <div class="portlet-title">
            <h1>#acs-subsite.Subsites#</h1>
          </div>
        </div>
        <div class="portlet">
          <include src="/packages/acs-subsite/lib/subsites">
        </div>
      </div>
    </td>
  </tr>

  <tr>
    <td valign="top" colspan="2">
      <ul class="compact">
          <if @show_members_page_link_p@>
            <li><a href="members/" class="button">#acs-subsite.Members#</a></li>
          </if>
  	  <li><a href="site-map/" class="button">#acs-subsite.UserSiteMap#</a></li>
          <if @untrusted_user_id@ ne 0>
            <if @main_site_p@ false>  
              <if @group_member_p@ true>
               <li><a href="group-leave" class="button" title="#acs-subsite.Leave_this_subsite#">#acs-subsite.Leave_subsite#</a></li>
              </if>
              <else>
                <if @can_join_p@ true>
                  <if @group_join_policy@ eq "open">
                    <li><a href="register/user-join" class="button" title="#acs-subsite.Join_this_subsite">#acs-subsite.Join_subsite#</a></li>
                  </if>
                  <else>
                    <li><a href="register/user-join" class="button" title="#acs-subsite.Req_membership_subs#">#acs-subsite.Request_membership#</a></li>
                  </else>
                </if>
              </else>
            </if>
          </if>
          <if @admin_p@ true> 
            <li><a href="admin/" class="button" title="#acs-subsite.Administer_subsite#">#acs-kernel.common_Administration#</a></li>
          </if>
      </ul>
    </td>
  </tr>
</table>
  

