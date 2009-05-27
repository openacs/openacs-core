<h3>Bug Tracker Summary for package @package_key@</h3>

<if @pkg_exists_p@ eq 1>
<table id="bug-tracker-summary">
  <tr>
    <th>Open Bugs: </th>
    <td><a href="/bugtracker/openacs/?f_component=@component_id@">@open@</a></td>
  </tr>
  <tr>
    <th>Latest Bug Opened: </th>
    <td><if @bug_exists_p@ eq 1>@bug.date@ <a href="/bugtracker/openacs/bug?bug_number=@bug.num@">@bug.summary@</a></if>
        <else>This package has no open bugs.</else>
    </td>
  </tr>
  <tr>
    <th>Latest Bug Fixed: </th>
    <td><if @fix_exists_p@ eq 1>@fix.date@ <a href="/bugtracker/openacs/bug?bug_number=@fix.num@">@fix.summary@</a>.</if>
        <else>No bugs have been fixed in this package.</else>
    </td>
  </tr>
  <tr>
    <th>Top Bug Submitters: </th>
    <td><multiple name="submitters"><%=[acs_community_member_link -user_id @submitters.user_id@] %> (@submitters.count@) </multiple> </td>
  </tr>
  <tr>
    <th>Top Bug Fixers: </th>
    <td><multiple name="fixers"><%=[acs_community_member_link -user_id @fixers.user_id@] %> (@fixers.count@) </multiple> </td>
  </tr>
</table>
</if>
<else>
  <p>There is no package with the name "@package_key@".</p>
</else>
