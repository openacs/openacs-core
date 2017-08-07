<master>
<property name="doc(title)">Confirm privilege modification for user #@user_id;noquote@</property>
<property name=context>@context;noquote@</property>

Are you sure you wish to @action@ admin privileges for user
<strong>@user_info.name@</strong> (@user_info.email@, #@user_id@) ?

<p></p>

<if @action@ eq "grant">
  <a href="@confirmed_url@">Grant privileges</a> |
</if>
<else>
  <a href="@confirmed_url@">Revoke privileges</a> |
</else>

<a href="@return_url@">Cancel</a>
