<master>
  <property name=title>@page_title@</property>
  <property name="context">@context@</property>
  <property name="user_info">first_names</property>
  <property name="focus">user_info.first_names</property>

<h2>Basic Information</h2>

<formtemplate id="user_info"></formtemplate>

<if @form_request_p@ true>
  <p>
    <b>&raquo;</b> <a href="../user/password-update">Change Password</a>
  </p>

  <p>
    <b>&raquo;</b> <a href="@community_member_url@">What other people see when they click your name</a>
  </p>

  <p>
    <b>&raquo;</b> <a href="unsubscribe">Unsubscribe from this site</a> (for a period of vacation or permanently)
  </p>


  <if @portrait_state@ eq upload>
    <h2>Portrait</h2>
    <p>
      Show everyone else at @system_name@ how great looking you are:  <a href="../user/portrait/upload">upload a portrait</a>
    </p>
  </if>
  <if @portrait_state@ eq show>
    <h2>Portrait</h2>
    <p>
      On @portrait_publish_date@, you uploaded <a href="../user/portrait/">@portrait_title@</a>.
    </p>
  </if>
</if>
