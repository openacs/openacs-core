<master>
<property name="title">@title;noquote@</property>
<property name="context">@context;noquote@</property>

<if @search_type@ eq "keyword">
  for name or email matching "@keyword@"
 </if><else>
 <if @search_type@ eq "email">
  for email "@email@"
 </if><else>
  for last name "@last_name@"
</else></else>


<if @only_authorized_p@ eq 0>
  We're showing all users, authorized or not (<a href="search?@export_authorize@&only_authorized_p=1">show only
  authorized</a>).
  <p>
</if><else>
  We're only showing authorized users (<a href="search?@export_authorize@&only_authorized_p=0">show all</a>).
  <p>
</else>

<ul>

<multiple name="user_search">
  <li><a href="@target@?user_id=@user_search.user_id@&@user_search.export_vars@&@passthrough_parameters@">@user_search.first_names@ @user_search.last_name@ (@user_search.email@)</a>
  <if @user_search.member_state@ ne "approved">
     <font color=red>@user_search.member_state@</font> @user_search.user_finite_state_links@
  </if></li>
</multiple>

<if @user_search:rowcount@ eq 0>
  <li>No users found.
</if><else>

  <if @user_search:rowcount@ gt 30>

    <if @only_authorized_p@ eq 0>
      We're showing all users, authorized or not (<a href="search?@export_authorize@&only_authorized_p=1">
      show only authorized</a>).
      <p>
    </if><else>
      We're only showing authorized users (<a href="search?@export_authorize@&only_authorized_p=0">show all</a>).
      <p>
    </else>

  </if>
</else>

</ul>

