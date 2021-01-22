<master>
<property name="doc(title)">Complex User Search</property>
<property name="context">@context;literal@</property>

<if @criteria:rowcount@ eq 0>
  all matching users
</if><else>
  <if @criteria:rowcount@ eq 1>
    for users matching the criterion:
    <ul>
    <multiple name="criteria">
      <li> @criteria.data@ </li>
    </multiple>
    </ul>
  </if><else>
    for users matching <strong> @combine_method@ </strong> of the criteria:
    <ul>
    <multiple name="criteria">
      <li> @criteria.data@ </li>
    </multiple>
    </ul>
  </else>
</else>

<hr>


<if @user_search:rowcount@ eq 0>
  <ul>
    <li>No users found.</li>
  </ul>
</if>
<else>

<ul>
  <multiple name="user_search">
    <li><a href="@target@?user_id=@user_search.user_id@&amp;@user_search.export_vars@&amp;@passthrough_parameters@">@user_search.first_names@ @user_search.last_name@ (@user_search.email@)</a>
    <if @user_search.member_state@ ne "approved">
       <span style="color:red">@user_search.member_state@</span> @user_search.user_finite_state_links;noquote@
    </if>
  </multiple>
</ul>

  <if @user_search:rowcount@ gt 30>

    <if @only_authorized_p;literal@ false>
      <p>
        We're showing all users, authorized or not (<a href="complex-search?@export_authorize@&amp;only_authorized_p=1">
        show only authorized</a>).
      <p>
    </if><else>
      <p>
        We're only showing authorized users (<a href="complex-search?@export_authorize@&amp;only_authorized_p=0">show all</a>).
      <p>
    </else>

  </if>
</else>


