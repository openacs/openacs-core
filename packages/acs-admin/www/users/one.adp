<master>
<property name=title>@first_names;noquote@ @last_name;noquote@</property>
<property name="context">@context;noquote@</property>

<h2>Basic Information</h2>

<include src="/packages/acs-subsite/lib/user-info" user_id="@user_id@" return_url="@return_url@">

<ul>
<li>User ID:  @user_id@</li>
<li><a href="@public_link@">View community member page</a></li>
<li>Registration date:  @registration_date@</li>
<li>Registration IP: @creation_ip@ (<a href="complex-search?target=one&amp;ip=@creation_ip@" title="other registrations from this IP address">others</a>)</li>
<li>Last visit: @last_visit_pretty@</li>


<if @portrait_p@ eq 1>
  <li>Portrait:  <a href="/shared/portrait?user_id=@user_id@">@portrait_title@</a></li>
</if>
</ul>

<if @user_id@ ne @ad_conn_user_id@>
  <if @warning_p@>
      <!-- RBM: Added August 1, 2003 --!>
      <p>
        <b>WARNING:</b> This user is a site-wide administrator (maybe the only one).
        Deleting or banning this user may mean you will be unable to administrate the site.
      </p>
  </if>
  <p>Member state: <b>@member_state@</b> - change member state: @user_finite_state_links;noquote@</p>
</if>
<else>
  <p>Member state: <b>@member_state@</b> <i>(cannot change state for yourself)</i></p>
</else>

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

<li><a href="become?user_id=@user_id@">Login as this user</a></li>
</ul>


