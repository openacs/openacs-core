<master>
<property name=title>Complex User Search</property>

<h2>Complex User Search</h2>

<if @criteria:rowcount@ eq 0>
  all users
</if><else>
  <if @criteria:rowcount@ eq 1>
    for users matching the criterion:
    <multiple name="criteria">
      <li> @criteria.data@ </li>
    </multiple>
  </if><else>
    for users matching <b> @combine_method@ </b> of the criteria:
    <multiple name="criteria">
      <li> @criteria.data@ </li>
    </multiple>
  </else>
</else>

<hr>

<ul>

<multiple name="user_search">

  <li><a href="@target@?user_id=@user_search.user_id@&@user_search.export_vars@&@passthrough_parameters@">@user_search.first_names@ @user_search.last_name@ (@user_search.email@)</a>
  <if @user_search.member_state@ ne "approved">
     <font color=red>@user_search.member_state@</font> @user_search.user_finite_state_links@
  </if>

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

