<master>
  <property name="title">#acs-subsite.Log_In#</property>
  <property name="context">{#acs-subsite.Log_In#}</property>

<if @expired_p@ true>
  <div class="general-message">#acs-subsite.lt_Your_login_has_expire#</div>
</if>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@email;noquote@" &="__adp_properties">

