<master>
  <property name="title">@system_name;noquote@</property>

<if @user_id@ eq 0>
  <div id="login-box" style="float: right;">
    <include src="/packages/acs-subsite/lib/login" return_url="/" username="@username@" authority_id="@authority_id@" &="__adp_properties">
  </div>
</if>


      <p><b>Open Architecture Community System @acs_version@ </b>at
      @system_name@. 

      <p><if @user_id@ gt 0>
        You are currently logged in as @user.first_names@ @user.last_name@.
      </if>
      <else>
        <b>Log in</b> in the box on the right, using the email
        address and password that you have just specified for the
        administrator.
      </else>
      </p>

      <if @sw_admin_p@ true>
        <p> 
      </if>

     

