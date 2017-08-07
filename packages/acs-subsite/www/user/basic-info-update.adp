<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<h1>#acs-subsite.Your_Account#</h1>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<include src="@user_info_template;literal@" &="user_id" &="return_url" &="__adp_properties" &="edit_p" &="message">
