<master>
<property name=title>Confirm privilege modification for user #@user_id@</property>
<property name=context>@context@</property>

Are you sure you wish to @action@ admin privileges for user #@user_id@?

<p></p>

<if @action@ eq "grant">
  <a href="@confirmed_url@">Grant privileges</a> |
</if>
<else>
  <a href="@confirmed_url@">Revoke privileges</a> |
</else>

<a href="@return_url@">Cancel</a>
