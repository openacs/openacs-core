<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>
  <property name="focus">@focus@</property>

  <if @authority_id@ not nil and @username@ not nil>
    <if @form_submitted_p@ false or @form_valid_p@ true>
      @recover_info.password_message@
    </if>
    <else>
      <formtemplate id="recover_password"></formtemplate>
    </else>
  </if>
  <else>
    <formtemplate id="recover_password"></formtemplate>
  </else>

