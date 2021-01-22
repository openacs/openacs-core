<property name="doc(title)">Valid State Abbrev</property>
<master>

<h1>Sample Users by State</h1>
<table cellpadding="4" cellspacing="0" border="1" bgcolor="#CCFFCC">
<tr bgcolor="#eeeeee"><td>@state_abbrev@</td></tr> 
<multiple name="users">
  <tr bgcolor="#ffffff"><td>
        <p>The @users.last_name@ Family</p>
          <ul>   
            <group column="last_name"> 
              <li>@users.first_name@ @users.last_name@</li> 
            </group>
          </ul>
  </td></tr>

</multiple>
</table>


