<master>
<property name=title>@first_names@ @last_name@</property>

<h2>@first_names@ @last_name@</h2>

@context_bar@

<hr>

<ul>
<li>Name:  @first_names@ @last_name@ (<a href="/user/basic-info-update?@export_edit_vars@">edit</a>)
<li>Email:  <a href="mailto:@email@">@email@</a> 
(<a href="/user/basic-info-update?@export_edit_vars@">edit</a>)
<li>Screen name:  @screen_name@ (<a href="/user/basic-info-update?@export_edit_vars@">edit</a>)
<li>User ID:  @user_id@
<li>Registration date:  @registration_date@

<if @last_visit@ not nil>
  <li>Last visit: @last_visit@
</if>

<if @portrait_p@ eq 1>
  <li>Portrait:  <a href="/shared/portrait?user_id=@user_id@">@portrait_title@</a>
</if>

<li> Member state: @member_state@ @user_finite_state_links@
</ul>

<multiple name="user_contributions">

  <H3>@user_contributions.pretty_plural@</H3>
  <ul>
  
  <group column="pretty_name">
    <li>@creation_date@: @user_contributions.object_name@
  </group>
  </ul>
  
</multiple>

<h3>Administrative Actions</h3>

<ul>
<li><a href="/user/password-update?@export_edit_vars@">Update this user's password</a><p>
<p>
<li><a href="/user/portrait/index.tcl?@export_edit_vars@">Manage this user's portrait</a><p>
<p>
<li><a href="become?user_id=@user_id@">Become this user!</a>
</ul>


