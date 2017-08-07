<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<if @search_type@ eq "keyword">
  for name or email matching "@keyword@"
 </if><else>
 <if @search_type@ eq "email">
  for email "@email@"
 </if><else>
  for last name "@last_name@"
</else></else>


<if @only_authorized_p;literal@ false>
  <p>
    <strong>Show</strong> | <a href="search?@export_authorize@&amp;only_authorized_p=1">Hide</a> unapproved users.
  </p>
</if>
<else>
  <p>
    <a href="search?@export_authorize@&amp;only_authorized_p=0">Show</a> | <strong>Hide</strong> unapproved users.
  </p>
</else>

<ul>

<multiple name="user_search">
  <li><a href="@target@?user_id=@user_search.user_id@&amp;@user_search.export_vars@&amp;@passthrough_parameters@">@user_search.first_names@ @user_search.last_name@ (@user_search.email@)</a>
  <if @user_search.member_state@ ne "approved">
     <span style="color:red">@user_search.member_state@</span> @user_search.user_finite_state_links;noquote@
  </if></li>
</multiple>

<if @user_search:rowcount@ eq 0>
  <li>No users found.
</if>

</ul>

