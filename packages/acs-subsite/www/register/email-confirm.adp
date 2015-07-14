<master>
  <property name="context">{#acs-subsite.Email_Confirmation#}</property>

<include src="@email_confirm_template;literal@" user_id="@user_id;literal@" token="@token;literal@" return_url="@return_url;literal@" />
