<master>
<property name="doc(title)">Users</property>
<property name="context">@context;literal@</property>

<ul>
  <li>total users: <a href="complex-search?target=one&amp;only_authorized_p=0">@n_users@</a> (@n_deleted_users@ deleted).  Last registration on @last_registration@ (<a href="registration-history">history</a>).

  <li><form method="get" action="search">
    <div><input type="hidden" name="target" value="one">
    <input type="hidden" name="only_authorized_p" value="0">
    Quick search: <input type="text" size="15" name="keyword">
                  <input type="submit" value="Find User">
    </div>
  </form><p></li>
  <li><a href="complex-search?target=one&amp;only_authorized_p=0&amp;only_needs_approval_p=1">Find all users needing approval</a></li>
  <li><a href="bouncing-users">Find all bouncing users</a></li>
  <li><a href="user-add">Add a user</a></li>
  <li><a href="/members/user-batch-add">Add a batch of users</a></li>
  <li><a href="/admin/manage-email-privacy">#acs-subsite.manage_users_email#</a><p></li>
  <li>
  <form method='get' action='complex-search'>
  <div>
    <input type='hidden' name='target' value="one">
    <input type='hidden' name='only_authorized_p' value="0">
    Complex search:
    <table cellspacing="1" border="0">
      <tr>
        <td align='right'>Group:</td>
        <td>
          <select name='limit_to_users_in_group_id'>
            @groups;noquote@
	  </select>
        </td>
      </tr>

      <tr>
        <td align='right'>Registration date:</td>
        <td>
          <table border="0" cellpadding="2" cellspacing="0">
            <tr>
              <td align='right'>over</td>
              <td>
                <input type='text' size="3" name='registration_before_days'>
                days ago
              </td>
            </tr> 
            <tr>
              <td align='right'>under</td>
              <td>
                <input type='text' size="3" name='registration_after_days'>
                days ago
              </td>
            </tr>
          </table>
        </td>
      </tr>

      <tr>
        <td align='right'>Last login:</td>
        <td>
          <table border="0" cellpadding="2" cellspacing="0">
            <tr>
              <td align='right'>over</td>
              <td>
                <input type='text' size="3" name='last_visit_before_days'>
                days ago
              </td>
            </tr> 
            <tr>
              <td align='right'>under</td>
              <td>
                <input type='text' size="3" name='last_visit_after_days'>
                days ago
              </td>
            </tr>
          </table>
        </td>
      </tr>

      <tr>
        <td align='right'>Number of visits:</td>
        <td>
          <table border="0" cellpadding="2" cellspacing="0">
            <tr>
              <td align='right'>less than</td>
              <td><input type='text' size="3" name='number_visits_below'></td>
            </tr>
            <tr>
              <td align='right'>more than </td>
              <td><input type='text' size="3" name='number_visits_above'></td>
            </tr>
          </table>
        </td>
      </tr>

      <tr>
        <td align='right'>Last name starts with:</td>
        <td> <input type='text' name='last_name_starts_with'> </td>
      </tr>
    
      <tr>
        <td align='right'>First names contain:</td>
        <td> <input type='text' name='first_names'> </td>
      </tr>
    
      <tr>
        <td align='right'>Email contains:</td>
        <td> <input type='text' name='email'> </td>
      </tr>
      <tr>
        <td align='right'>IP Address:</td>
        <td> <input type='text' name='ip'> </td>
      </tr>

      <tr>
        <td>&nbsp;</td>
        <td>
          Join the above criteria by
          <input type="radio" name='combine_method' value="all" checked> and
          <input type="radio" name='combine_method' value="any"> or
        </td>
      </tr>

      <tr>
        <td colspan="2" align='center'>
          <input type="submit" name='Submit' value="Submit">
        </td>
      </tr>
    </table>
  </div>
  </form>
</ul>

