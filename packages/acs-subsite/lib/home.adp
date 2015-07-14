<table>
  <tr valign="top"> 
    <td style="width:35%">
      <div class="portlet-wrapper">
        <div class="portlet-header">
          <div class="portlet-title">
            <h1>#acs-subsite.Edit_Options#</h1>
          </div>
        </div>
        <div class="portlet">
          <ul>
            <li><a href="../user/password-update">#acs-subsite.Change_my_Password#</a></li>

            <if @notifications_url@ not nil>
              <li><a href="@notifications_url@">#acs-subsite.Manage_your_notifications#</a></li>
            </if>

            <if @account_status@ ne "closed">
              <li><a href="unsubscribe">#acs-subsite.Close_your_account#</a></li>
            </if>
          </ul>
        </div>
      </div>

      <div class="portlet-wrapper">
        <div class="portlet-header">
          <div class="portlet-title">
            <h1>#acs-subsite.Privacy#</h1>
          </div>
        </div>
        <div class="portlet">
          <ul>
            <li><a href="@community_member_url@">#acs-subsite.lt_What_other_people_see#</a></li>
            <li><a href="@whos_online_url@">#acs-subsite.Whos_Online_link_label#</a></li>
            <li><a href="../user/email-privacy-level">#acs-subsite.Change_my_email_P#</a></li>
          </ul>

          <if @invisible_p@ true>
            #acs-subsite.Currently_invisible_msg#
            <ul>
              <li><a href="@make_visible_url@">#acs-subsite.Make_yourself_visible_label#</a></li>
            </ul>
          </if>
          <else>
            #acs-subsite.Currently_visible_msg#
            <ul>
              <li><a href="@make_invisible_url@">#acs-subsite.Make_yourself_invisible_label#</a></li>
            </ul>
          </else>
        </div>
      </div>

    </td>
    <td>

      <div class="portlet-wrapper">
        <div class="portlet-header">
          <div class="portlet-title">
            <h1>#acs-subsite.My_Account#</h1>
          </div>
        </div>
        <div class="portlet">
          <include src="@user_info_template;literal@" />
          <if @account_status@ eq "closed">
            #acs-subsite.Account_closed_workspace_msg#
           </if>
        </div>
      </div>

      <if @portrait_state@ eq upload>
        <div class="portlet-wrapper">
          <div class="portlet-header">
            <div class="portlet-title">
              <h1>#acs-subsite.Your_Portrait#</h1>
            </div>
          </div>
          <div class="portlet">
            <p>
              #acs-subsite.lt_Show_everyone_else_at#  <a href="@portrait_upload_url@">#acs-subsite.upload_a_portrait#</a>
            </p>
          </div>
        </div>
      </if>

      <if @portrait_state@ eq show>
        <div class="portlet-wrapper">  
          <div class="portlet-header">
            <div class="portlet-title">
              <h1>#acs-subsite.Your_Portrait#</h1>
            </div>
          </div>
          <div class="portlet">
            <p>#acs-subsite.lt_On_portrait_publish_d#.</p>
            <table>
              <tr valign="top">
                <td>
                  <img height=100 src="/shared/portrait-bits.tcl?user_id=@user_id@" alt="Portrait">
                  <p><a href="/user/portrait/?return_url=/pvt/home">#acs-subsite.Edit#</a></p>
                </td>
                <td>
                  @portrait_description@
                </td>
              </tr>
            </table>
          </div>
        </div>
      </if>

      <div class="portlet-wrapper">
        <div class="portlet-header">
          <div class="portlet-title">
            <h1>#acs-subsite.Groups#</h1>
          </div>
        </div>
        <div class="portlet">
          <list name="fragments">
            @fragments:item;noquote@
          </list>
        </div>
      </div>
    </td>
  </tr>
</table>
