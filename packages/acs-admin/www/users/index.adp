<master>
<property name=title>Users</property>
<property name="context">@context;noquote@</property>

<ul>
  <li>total users: <a href="complex-search?target=one&only_authorized_p=0">@n_users@</a> (@n_deleted_users@ deleted).  Last registration on @last_registration@ (<a href="registration-history">history</a>).</li>


  <p>
  <FORM METHOD=get ACTION=search>
    <input type="hidden" name="target" value="one">
    <input type="hidden" name="only_authorized_p" value="0">
    <li>Quick search: <input type="text" size="15" name="keyword">
                  <input type="submit" value="Find User">
  </FORM>
        </p>
  <li><a href="complex-search?target=one&only_authorized_p=0&only_needs_approval_p=1">Find all users needing approval</a></li>
  <li><a href="bouncing-users">Find all bouncing users</a></li>
  <li><a href="user-add">Add a user</a></li>
  <li><a href="/members/user-batch-add">Add a batch of users</a></li>
  <li><a href="/admin/manage-email-privacy">#acs-subsite.manage_users_email#</a></li>

  <form method='get' action='complex-search'>
    <input type='hidden' name='target' value="one">
    <input type='hidden' name='only_authorized_p' value="0">
    <li>Complex search:
    <table cellspacing=1 border=0>

      <tr bgcolor='#ffffff'>
        <td align='right'>Group:</td>
        <td>
          <select name='limit_to_users_in_group_id'>
            <option></option>
            @groups@
        </td>
      </tr>

      <tr bgcolor='#ffffff'>
        <td align='right'>Registration date:</td>
        <td>
          <table border=0 cellpadding=2 cellspacing=0>
            <tr>
              <td align='right'>over</td>
              <td>
                <input type='text' size=3 name='registration_before_days'>
                days ago
              </td>
            </tr> 
            <tr>
              <td align='right'>under</td>
              <td>
                <input type='text' size=3 name='registration_after_days'>
                days ago
              </td>
            </tr>
          </table>
        </td>
      </tr>

      <tr bgcolor='#ffffff'>
        <td align='right'>Last login:</td>
        <td>
          <table border=0 cellpadding=2 cellspacing=0>
            <tr>
              <td align='right'>over</td>
              <td>
                <input type='text' size=3 name='last_visit_before_days'>
                days ago
              </td>
            </tr> 
            <tr>
              <td align='right'>under</td>
              <td>
                <input type='text' size=3 name='last_visit_after_days'>
                days ago
              </td>
            </tr>
          </table>
        </td>
      </tr>

      <tr bgcolor='#ffffff'>
        <td align='right'>Number of visits:</td>
        <td>
          <table border=0 cellpadding=2 cellspacing=0>
            <tr>
              <td align='right'>less than</td>
              <td><input type='text' size=3 name='number_visits_below'></td>
            </tr>
            <tr>
              <td align='right'>more than </td>
              <td><input type='text' size=3 name='number_visits_above'></td>
            </tr>
          </table>
        </td>
      </tr>

      <tr bgcolor='#ffffff'>
        <td align='right'>Last name starts with:</td>
        <td> <input type='text' name='last_name_starts_with'> </td>
      </tr>
    
      <tr bgcolor='#ffffff'>
        <td align='right'>First names contain:</td>
        <td> <input type='text' name='first_names'> </td>
      </tr>
    
      <tr bgcolor='#ffffff'>
        <td align='right'>Email contains:</td>
        <td> <input type='text' name='email'> </td>
      </tr>
      <tr bgcolor='#ffffff'>
        <td align='right'>IP Address:</td>
        <td> <input type='text' name='ip'> </td>
      </tr>

      <tr bgcolor='#ffffff'>
        <td>&nbsp;</td>
        <td>
          Join the above criteria by
          <input type=radio name='combine_method' value="all" checked> and
          <input type=radio name='combine_method' value="any"> or
        </td>
      </tr>

      <tr bgcolor='#ffffff'>
        <td colspan=2 align='center'>
          <input type=submit name='Submit' value=Submit>
        </td>
      </tr>
    </table>

  </FORM>


  <p>

</ul>

