<master>
  <property name=title>@page_title@</property>
  <property name="context">@context;noquote@</property>
  <property name="focus">user_info.first_names</property>

<h2>#acs-subsite.Basic_Information#</h2>

<formtemplate id="user_info"></formtemplate>

<if @form_request_p@ true>
  <p>
    <b>&raquo;</b> <a href="../user/password-update?return_url=@pvt_home_url@">#acs-subsite.Change_my_Password#</a>
  </p>

  <p>
    <b>&raquo;</b> <a href="@community_member_url@">What other people see when they click your name</a>
  </p>

  <p>
    <b>&raquo;</b> <a href="unsubscribe">#acs-subsite.Unsubscribe#</a> (#acs-subsite.lt_for_a_period_of_vacat#)
  </p>

  <if @portrait_state@ eq upload>
    <h2>#acs-subsite.Your_Portrait#</h2>
    <p>
      #acs-subsite.lt_Show_everyone_else_at#  <a href="@portrait_upload_url@">#acs-subsite.upload_a_portrait#</a>
    </p>
  </if>
  <if @portrait_state@ eq show>
    <h2>#acs-subsite.Your_Portrait#</h2>
    <p>
      #acs-subsite.lt_On_portrait_publish_d#.
    </p>
  </if>
</if>
