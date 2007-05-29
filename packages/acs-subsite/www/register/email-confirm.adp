<master>
  <property name="context">{#acs-subsite.Email_Confirmation#}</property>

<include src="@email_confirm_template@" user_id="@user_id@" token="@token;noquote@" return_url="@return_url;noquote@" />
