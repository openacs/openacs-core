<master>
<property name="title">@title@</property>
<property name="context">@context@</property>

<if @chat_system_name@ not nil>
  This page is mostly useful in conjunction with 
  <a href="/chat">@chat_system_name@</a>.
</if>

<ul>

<multiple name="users">

  <if @connected_user_id@ eq 0>
    <li><a href="/shared/community-member?user_id=@users.user_id@">@users.first_names@ @users.last_name@</a>
  </if>
  <else>
    <li><a href="/shared/community-member?user_id=@users.user_id@">@users.first_names@ @users.last_name@</a> (@users.email@)
  </else>

</multiple>

</ul>

These are the registered users who have 
requested a page from this server within the last
@last_visit_interval@ seconds.

<p>

On a public Internet service, the number of casual surfers
(unregistered) will outnumber the registered users by at least 10 to
1.  Thus there could be many more people using this service than it
would appear.

