<master>
<property name=title>@first_names@ @last_name@</property>
<property name="context">@context@</property>

<ul>
<li>Name:  @first_names@ @last_name@ (<a href="@public_link@">public page</a>)</li>
<li>Email:  <a href="mailto:@email@">@email@</a></li>
<li>Screen name:  @screen_name@ </li>
<if @url@ not nil>
  <li>Homepage: <a href="@url@">@url@</a></li>
</if>
<li>User ID:  @user_id@</li>
</ul>
[<a href="/user/basic-info-update?@export_edit_vars@">edit user information</a>]
<ul>
<li>Registration date:  @registration_date@</li>
<li>Registration IP: @creation_ip@ (<a href="complex-search?target=one&amp;ip=@creation_ip@" title="other registrations from this IP address">others</a>)</li>
<if @last_visit@ not nil>
  <li>Last visit: @last_visit@</li>
</if>

<if @portrait_p@ eq 1>
  <li>Portrait:  <a href="/shared/portrait?user_id=@user_id@">@portrait_title@</a></li>
</if>
</ul>
Member state: @member_state@ @user_finite_state_links@

<h2>This user is a member of the following groups:</h2>
<p>Note: These are the groups to which the user has been granted 
<em>direct</em> membership.</p>

<ul>
  <multiple name="direct_group_membership">
    <li>@direct_group_membership.group_name@
        (<a href="/admin/relations/remove?rel_id=@direct_group_membership.rel_id@&return_url=@return_url@">Remove</a>)</li>
  </multiple>
</ul>
<p>
And the user is a member of these groups by virtue of being directly
added (see above) or because these groups are components of the groups
above.
</p>

<ul><li><strong><multiple name="all_group_membership"> @all_group_membership.group_name@<if @all_group_membership.rownum@ lt @all_group_membership:rowcount@>, </if> </multiple>
  </strong>
  </li>
</ul>

<multiple name="user_contributions">

  <h2>@user_contributions.pretty_plural@</h2>
  <ul>
  
  <group column="pretty_name">
    <li>@creation_date@: @user_contributions.object_name@</li>
  </group>
  </ul>
  
</multiple>

<h2>Administrative Actions</h2>

<ul>
<if @admin_p@>
  <li><a href="modify-admin-privileges?user_id=@user_id@&action=revoke">Revoke site-wide administration privileges</a></li>
</if>
<else>
  <li><a href="modify-admin-privileges?user_id=@user_id@&action=grant">Grant site-wide administration privileges</a></li>
</else>

<li><a href="/user/password-update?@export_edit_vars@">Update this user's password</a></li>

<li><a href="/user/portrait/index.tcl?@export_edit_vars@">Manage this user's portrait</a></li>

<li><a href="become?user_id=@user_id@">Become this user!</a></li>
</ul>


