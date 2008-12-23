<master>
<property name=title>@user_info.first_names;noquote@ @user_info.last_name;noquote@</property>
<property name="context">@context;noquote@</property>

<h2>Basic Information</h2>

<include src="/packages/acs-subsite/lib/user-info" user_id="@user_id@" return_url="@return_url@">

<ul>
<li>User ID:  @user_id@</li>
<li><a href="@user_info.url@">View community member page</a></li>
<li>Registration date:  @user_info.creation_date_pretty@</li>
<li>Registration IP: @user_info.creation_ip@ (<a href="@user_info.by_ip_url@" title="Other registrations from this IP address">others</a>)</li>
<li>Last visit: @user_info.last_visit_pretty@</li>


<if @portrait_url@ not nil>
  <li>Portrait:  <a href="@portrait_url@">@portrait_title@</a></li>
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
  <p>Member state: <b>@user_info.member_state@</b> - change member state: @user_finite_state_links;noquote@<br>
  Delete user: <a href="@delete_user_url@">temporarily</a>, <a href="@delete_user_permanent_url@">permanently</a></p>
</if>
<else>
  <p>Member state: <b>@user_info.member_state@</b> <i>(cannot change state for yourself)</i></p>
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

<ul>
  <multiple name="all_group_membership">
    <li>@all_group_membership.group_name@</li>
  </multiple>
</ul>

<multiple name="user_contributions">

  <h2>@user_contributions.pretty_plural@</h2>
  <ul>
  
  <group column="pretty_name">
    <li>@user_contributions.creation_date@: @user_contributions.object_name@</li>
  </group>
  </ul>
  
</multiple>

<h2>Administrative Actions</h2>

<ul>
<if @site_wide_admin_p@ true>
  <li><a href="modify-admin-privileges?user_id=@user_id@&action=revoke">Revoke site-wide administration privileges</a></li>
</if>
<else>
  <li><a href="modify-admin-privileges?user_id=@user_id@&action=grant">Grant site-wide administration privileges</a></li>
</else>

<li>Merge this user with:
   <form method=get action=search>
    <input type="hidden" name="target" value="merge">
    <input type="hidden" name="limit_to_user_id" value="@user_id@">
    <input type="hidden" name="from_user_id" value="@user_id@">
    <input type="hidden" name="only_authorized_p" value="0">
    <input type="text" size="15" name="keyword">
    <input type="submit" value="Find User">
  </form>
 </li>

<if @password_reset_url@ not nil>
  <li><a href="@password_reset_url@">Reset this user's password</a></li>
</if>

<if @password_update_url@ not nil>
  <li><a href="@password_update_url@">Update this user's password</a></li>
</if>

<li><a href="@portrait_manage_url@">Manage this user's portrait</a></li>

<li><a href="become?user_id=@user_id@">Login as this user</a></li>
</ul>


